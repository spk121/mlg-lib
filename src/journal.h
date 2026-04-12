#ifndef MLG_JOURNAL_H
#define MLG_JOURNAL_H

SCM mlg_send_alist_to_journal (SCM s_alist);
SCM mlg_send_alist_to_syslog (SCM s_log_level, SCM s_alist);
void init_journal_lib ();

#endif
