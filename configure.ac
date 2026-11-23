AC_INIT(mlg_lib, 1.0, mike@lonelycactus.com)
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_SRCDIR([module/mlg/strings.scm])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])
AC_CONFIG_MACRO_DIRS([m4])
# The host triplet is passed to guild as the compilation target.
AC_CANONICAL_HOST

GUILE_PKG([3.0 2.2])
GUILE_PROGS
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

    # Compiled .go scheme libraries go here
    AC_MSG_CHECKING([Guile object directory])
    guileobjectdir=$GUILE_SITE_CCACHE
    AC_MSG_RESULT([$guileobjectdir])
    AC_SUBST(guileobjectdir)])

AC_CONFIG_FILES([Makefile])
AC_CONFIG_FILES([tools/uninstalled-env], [chmod +x tools/uninstalled-env])
AC_REQUIRE_AUX_FILE([test-driver])
AC_REQUIRE_AUX_FILE([test-driver.scm])

AC_OUTPUT
