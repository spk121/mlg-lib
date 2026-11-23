(use-modules (srfi srfi-64)
             (mlg utils))

(test-begin "t-mlg-utils")

;; getpagesize, now called through the FFI instead of a C extension
(test-assert "getpagesize is a positive power of two"
  (let ((n (getpagesize)))
    (and (exact-integer? n) (> n 0) (zero? (logand n (1- n))))))

;; XDG directories
(define test-home
  (string-append (or (getenv "TMPDIR") "/tmp")
                 "/t-mlg-utils-" (number->string (getpid))))
(mkdir test-home)
(mkdir (string-append test-home "/.config"))
(call-with-output-file (string-append test-home "/.config/user-dirs.dirs")
  (lambda (port)
    (display "# comment\nXDG_DESKTOP_DIR=\"$HOME/Desktop\"\n" port)
    (display "XDG_MUSIC_DIR=\"/srv/music\"\nXDG_BAD_DIR=nothing\n" port)))
(define saved-home (getenv "HOME"))
(setenv "HOME" test-home)
(unsetenv "XDG_CONFIG_HOME")

(test-equal "get-user-special-dir relative to $HOME"
  (string-append test-home "/Desktop") (get-user-special-dir "desktop"))
(test-equal "get-user-special-dir absolute" "/srv/music"
  (get-user-special-dir "music"))
(test-equal "get-user-special-dir missing entry" #f
  (get-user-special-dir "videos"))
(test-equal "get-user-special-dir malformed entry" #f
  (get-user-special-dir "bad"))
(setenv "XDG_CONFIG_HOME" "/nonexistent")
(test-equal "get-user-special-dir without a config file" #f
  (get-user-special-dir "desktop"))
(unsetenv "XDG_CONFIG_HOME")

(setenv "XDG_RUNTIME_DIR" "/run/user/1234")
(test-equal "get-user-runtime-dir uses XDG_RUNTIME_DIR" "/run/user/1234"
  (get-user-runtime-dir))

(unsetenv "HOME")
(test-assert "get-home-dir without HOME" (string? (get-home-dir)))

(if saved-home (setenv "HOME" saved-home))
(delete-file (string-append test-home "/.config/user-dirs.dirs"))
(rmdir (string-append test-home "/.config"))
(rmdir test-home)

(test-equal "build-filename" "/a/b/c" (build-filename "/a/" "/b/" "c"))

(test-end "t-mlg-utils")
