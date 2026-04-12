#if HAVE_CONFIG_H
#include "config.h"
#endif
#if HAVE_SYSTEMD_SD_JOURNAL_H
#define SD_JOURNAL_SUPPRESS_LOCATION
#include <systemd/sd-journal.h>
#endif
#if HAVE_SYSLOG_H
#include <syslog.h>
#endif
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <sys/uio.h>
#include <libguile.h>
#include "journal.h"

/* Log level bits, mirroring the constants defined in (mlg logging).
 * These must be kept in sync with that module. */
#define MLG_LOG_LEVEL_ERROR    (1 << 2)
#define MLG_LOG_LEVEL_CRITICAL (1 << 3)
#define MLG_LOG_LEVEL_WARNING  (1 << 4)
#define MLG_LOG_LEVEL_MESSAGE  (1 << 5)
#define MLG_LOG_LEVEL_INFO     (1 << 6)
#define MLG_LOG_LEVEL_DEBUG    (1 << 7)

static char safe_char (wchar_t wc);
static char *scm_to_variable_name_string (SCM s_str, size_t *len);

/* Look up a string-keyed entry in a Scheme alist.
 * Returns the cdr (value) of the matching pair, or SCM_BOOL_F if absent. */
static SCM
alist_ref (SCM alist, const char *key)
{
  SCM pair = scm_assoc (scm_from_utf8_string (key), alist);
  return scm_is_true (pair) ? scm_cdr (pair) : SCM_BOOL_F;
}

/* Given an alist of key/value pairs, this procedure
 * reformats the data to be accepted by the systemd journal
 * and sends it to the systemd journal.
 * The keys must be either strings or symbols.
 * The values must be either strings or bytevectors.
 * If the keys or values are the wrong type, they are ignored.

 * It will return the number of entries actually logged.
 */
SCM
mlg_send_alist_to_journal (SCM s_alist)
{
  int list_len = 0;
  int count = 0;
  int ret = -1;
  size_t c_key_len = 0;
  char *c_key = NULL;

  if (!scm_is_true (scm_list_p (s_alist))
      || scm_is_null (s_alist))
    return scm_from_int (0);

  list_len = scm_to_int (scm_length (s_alist));
  struct iovec *c_entries
    = (struct iovec *) malloc (sizeof (struct iovec) * list_len);
  for (int i = 0; i < list_len; i ++)
    {
      SCM s_entry, s_key, s_val;
      s_entry = scm_list_ref (s_alist, scm_from_int (i));
      if (scm_is_true (scm_pair_p (s_entry)))
        {
          s_key = scm_car (s_entry);
          s_val = scm_cdr (s_entry);
          if (scm_is_symbol (s_key))
            s_key = scm_symbol_to_string (s_key);

          if (scm_is_string (s_key)
              && (scm_is_string (s_val)
                  || scm_is_bytevector (s_val)))
            {
              c_key = scm_to_variable_name_string (s_key, &c_key_len);
              if (c_key == NULL)
                continue;

              if (scm_is_string (s_val))
                s_val = scm_string_to_utf8 (s_val);
              if (SCM_BYTEVECTOR_LENGTH (s_val) == 0)
                {
                  free (c_key);
                  c_key = NULL;
                  continue;
                }

              size_t total_len = c_key_len + SCM_BYTEVECTOR_LENGTH(s_val) + 1;
              c_entries[count].iov_base = (void *) malloc (total_len);
              memcpy ((char *) c_entries[count].iov_base, c_key, c_key_len);
              ((char *)(c_entries[count].iov_base))[c_key_len] = '=';
              memcpy ((char *)c_entries[count].iov_base + c_key_len + 1,
                      SCM_BYTEVECTOR_CONTENTS (s_val),
                      SCM_BYTEVECTOR_LENGTH (s_val));
              c_entries[count].iov_len = total_len;
              count ++;
              free (c_key);
              c_key = NULL;
            }
        }
    }
  if (count > 0)
    {
#if HAVE_SYSTEMD_SD_JOURNAL_H
      ret = sd_journal_sendv (c_entries, count);
#else
      ret = -1;
#endif
      for (int i = 0; i < count; i ++)
        free (c_entries[i].iov_base);
    }
  free (c_entries);
  free (c_key);
  if (ret < 0)
    return scm_from_int (0);
  return scm_from_int (count);
}

/* Convert a wchar_t to an ASCII uppercase letter, digit, or
 * underscore. */
static char
safe_char (wchar_t wc)
{
  if (wc == (wchar_t) '_')
    return '_';
  else if (wc >= (wchar_t) '0' && wc <= (wchar_t) '9')
    return (char) wc;
  else if (wc >= (wchar_t) 'A' && wc <= (wchar_t) 'Z')
    return (char) wc;
  else if (wc >= (wchar_t) 'a' && wc <= (wchar_t) 'z')
    return (char) (wc - (wchar_t) ' ');
  else if (wc == 0xAA)
    return 'A';
  else if (wc == 0xB2)
    return '2';
  else if (wc == 0xB3)
    return '3';
  else if (wc == 0xB9)
    return '1';
  else if ((wc >= 0xC0 && wc <= 0xC6) || (wc >= 0xE0 && wc <= 0xE6))
    return 'A';
  else if (wc == 0xC7 || wc == 0xE7)
    return 'C';
  else if ((wc >= 0xC8 && wc <= 0xCB) || (wc >= 0xE8 && wc <= 0xEB))
    return 'E';
  else if ((wc >= 0xCC && wc <= 0xCF) || (wc >= 0xEC && wc <= 0xEF))
    return 'I';
  else if (wc == 0xD1 || wc == 0xF1)
    return 'N';
  else if ((wc >= 0xD2 && wc <= 0xD6) || wc == 0xD8
           || (wc >= 0xF2 && wc <= 0xF6) || wc == 0xF8)
    return 'O';
  else if ((wc >= 0xD9 && wc <= 0xDC) || (wc >= 0xF9 && wc <= 0xFC))
    return 'U';
  else if (wc == 0xDF)
    return 'S';
  else if (wc == 0xFD || wc == 0xFF)
    return 'Y';
  else
    return '_';
}

/* This takes any string and tries to convert it into a string that is
 * safe for use as systemd journal variable name, e.g., with only
 * ASCII uppercase letters, digits, and underscores and starting with
 * a letter. */
static char *
scm_to_variable_name_string (SCM s_str, size_t *ret_len)
{
  SCM_ASSERT (scm_is_string (s_str), s_str, SCM_ARG1, "send-alist-to-journal");
  int underscore_start = 0;
  size_t len = scm_c_string_length (s_str);

  if (len == 0)
    return NULL;

  if (safe_char (SCM_CHAR (scm_c_string_ref (s_str, 0))) == '_')
    underscore_start = 1;

  char *c_str = (char *) malloc (sizeof(char) * (len + 1 + underscore_start));
  if (underscore_start)
    c_str[0] = 'X';
  for (int i = 0; i < len; i ++)
    {
      c_str[i + underscore_start]
        = safe_char (SCM_CHAR (scm_c_string_ref (s_str, i)));
    }
  c_str[len + underscore_start] = '\0';
  *ret_len = len + underscore_start;
  return c_str;
}

/* Send a structured log message to the system syslog daemon.
 *
 * S_LOG_LEVEL is the integer log level (mlg LOG_LEVEL_* bits).
 * S_ALIST is a string-keyed alist; the following fields are recognised:
 *   MESSAGE            - the text to log (required)
 *   SYSLOG_IDENTIFIER  - passed as the ident argument to openlog(3)
 *   SYSLOG_FACILITY    - facility code (integer string, e.g. "1" for LOG_USER)
 *
 * Returns #t on success, #f if syslog support was not compiled in or if
 * no MESSAGE field was found.
 */
SCM
mlg_send_alist_to_syslog (SCM s_log_level, SCM s_alist)
{
#if HAVE_SYSLOG && HAVE_SYSLOG_H
  if (!scm_is_true (scm_list_p (s_alist)) || scm_is_null (s_alist))
    return SCM_BOOL_F;

  /* Map the mlg log level to a syslog priority. */
  int log_level = scm_to_int (s_log_level);
  int priority;
  if      (log_level & MLG_LOG_LEVEL_ERROR)    priority = LOG_ERR;
  else if (log_level & MLG_LOG_LEVEL_CRITICAL) priority = LOG_WARNING;
  else if (log_level & MLG_LOG_LEVEL_WARNING)  priority = LOG_WARNING;
  else if (log_level & MLG_LOG_LEVEL_MESSAGE)  priority = LOG_NOTICE;
  else if (log_level & MLG_LOG_LEVEL_INFO)     priority = LOG_INFO;
  else                                          priority = LOG_DEBUG;

  /* Optional SYSLOG_FACILITY: stored as the raw facility code (0=kern,
   * 1=user, 2=mail, ...).  Shift left by 3 to get the syslog.h value. */
  int facility = LOG_USER;
  SCM s_facility = alist_ref (s_alist, "SYSLOG_FACILITY");
  if (scm_is_string (s_facility))
    {
      char *fac_str = scm_to_utf8_string (s_facility);
      facility = atoi (fac_str) << 3;
      free (fac_str);
    }

  /* Optional SYSLOG_IDENTIFIER: the program name shown in the log.
   * openlog(3) keeps a reference to the ident pointer until closelog(3)
   * is called, so we must not free it until after closelog. */
  char *ident = NULL;
  SCM s_ident = alist_ref (s_alist, "SYSLOG_IDENTIFIER");
  if (scm_is_string (s_ident))
    ident = scm_to_utf8_string (s_ident);

  openlog (ident, LOG_PID, facility);

  /* Extract and log the MESSAGE field. */
  SCM s_message = alist_ref (s_alist, "MESSAGE");
  if (!scm_is_string (s_message))
    {
      closelog ();
      free (ident);   /* free(NULL) is safe */
      return SCM_BOOL_F;
    }

  char *message = scm_to_utf8_string (s_message);
  syslog (priority, "%s", message);
  free (message);

  closelog ();
  free (ident);

  return SCM_BOOL_T;
#else
  return SCM_BOOL_F;
#endif
}

void
init_journal_lib ()
{
  scm_c_define_gsubr ("send-alist-to-journal", 1, 0, 0,
                      mlg_send_alist_to_journal);
  scm_c_define_gsubr ("send-alist-to-syslog", 2, 0, 0,
                      mlg_send_alist_to_syslog);
}
