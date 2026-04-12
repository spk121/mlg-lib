AC_INIT(mlg_lib, 1.0, mike@lonelycactus.com)
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_SRCDIR([src/journal.c])
AC_CONFIG_HEADERS([src/config.h])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])
AC_CONFIG_MACRO_DIRS([m4])
AM_PROG_AR
AC_PROG_CC

AC_CHECK_HEADERS([systemd/sd-journal.h unistd.h syslog.h])
AC_SEARCH_LIBS([sd_journal_sendv],[systemd])
AC_CHECK_FUNCS([sysconf openlog syslog closelog])

GUILE_PKG([3.0 2.2])
GUILE_PROGS
GUILE_FLAGS
GUILE_SITE_DIR

AC_SUBST([GUILE_EFFECTIVE_VERSION])

################
# Guile has three directories that don't follow the GNU File System
# Heirarchy Standards.  If one follows the GNU FHS, files get installed
# in directories in which Guile does not search for them by default.
AC_ARG_WITH([gnu-filesystem-hierarchy],
            [AS_HELP_STRING([--with-gnu-filesystem-hierarchy],
                            [Strictly follow GNU File System Hierarchy when installing, instead of querying Guile to discover the install directories that it expects.])])

AS_CASE(["x$with_gnu_filesystem_hierarchy"], [xyes],
    [
    # Follow the GNU File System Hierarchy Standard correctly
    # Installed .scm scheme libraries go here
    AC_MSG_CHECKING([Guile site directory])
    guilesitedir="\${datadir}/guile/site/$GUILE_EFFECTIVE_VERSION"
    AC_MSG_RESULT([$guilesitedir])
    AC_SUBST(guilesitedir)

    # Compiled libguile-*.so extension libraries go here
    AC_MSG_CHECKING([Guile extension directory])
    guileextensiondir="\${libdir}/guile/$GUILE_EFFECTIVE_VERSION"
    AC_MSG_RESULT([$guileextensiondir])
    AC_SUBST(guileextensiondir)

    # Compiled .go scheme libraries go here
    AC_MSG_CHECKING([Guile object directory])
    guileobjectdir="\${libdir}/guile/$GUILE_EFFECTIVE_VERSION/site-ccache"
    AC_MSG_RESULT([$guileobjectdir])
    AC_SUBST(guileobjectdir)],
    [
    # Get the installation directories from Guile
    # Installed .scm scheme libraries go here
    AC_MSG_CHECKING([Guile site directory])
    guilesitedir=$GUILE_SITE
    AC_MSG_RESULT([$guilesitedir])
    AC_SUBST(guilesitedir)

    # Compiled libguile-*.so extension libraries go here
    AC_MSG_CHECKING([Guile extension directory])
    guileextensiondir=$GUILE_EXTENSION
    AC_MSG_RESULT([$guileextensiondir])
    AC_SUBST(guileextensiondir)

    # Compiled .go scheme libraries go here
    AC_MSG_CHECKING([Guile object directory])
    guileobjectdir=$GUILE_SITE_CCACHE
    AC_MSG_RESULT([$guileobjectdir])
    AC_SUBST(guileobjectdir)])

################
# Check for Libtool

LT_PREREQ([2.2])
LT_INIT([disable-fast-install disable-static win32-dll])

AC_CONFIG_FILES([Makefile])
AC_CONFIG_FILES([tools/uninstalled-env], [chmod +x tools/uninstalled-env])
AC_REQUIRE_AUX_FILE([test-driver])
AC_REQUIRE_AUX_FILE([test-driver.scm])

AC_OUTPUT
