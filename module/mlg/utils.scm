;;; -*- mode: scheme; coding: us-ascii; indent-tabs-mode: nil; -*-
;;; (mlg utils) - more helper functions
;;; Copyright (C) 2017, 2019 Michael L. Gran <spk121@yahoo.com>
;;;
;;; This program is free software: you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License as
;;; published by the Free Software Foundataion, either version 3 of
;;; this License, or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see
;;; <http://www.gnu.org/licenses/>

(define-module (mlg utils)
  #:use-module (srfi srfi-1)
  #:use-module (ice-9 rdelim)
  #:use-module (system foreign)
  #:export (get-prgname
            get-user-name

            ;; Path utils
            search-path-separator-string
            get-system-data-dirs

            ;; File utils
            build-filename
            get-home-dir
            get-tmp-dir
            get-user-data-dir
            get-user-config-dir
            get-user-cache-dir
            get-user-runtime-dir
            get-user-special-dir

            ;; Searches
            find-data-file

            getpagesize))

(define (search-path-separator-string)
  (let ((osname (utsname:sysname (uname))))
    (cond
     ((string=? osname "Windows")
      ";")
     (else
      ":"))))

(define (strip-end-separator str separator)
  "Return a substring of STR that does not include
the SEPARATOR string if it appears at the end of STR."
  (let ((str-len (string-length str))
        (separator-len (string-length separator)))
    (cond
     ((or (zero? str-len)
          (zero? separator-len)
          (< str-len separator-len))
      str)

     ;; Check if SEPARATOR is at the end of STR
     ((string= str separator (- str-len separator-len))
      ;; Return a copy of STR without SEPARATOR
      (substring/read-only str 0 (- str-len separator-len)))
     (else
      str))))

(define (strip-separators origstr separator)
  "Return a substring of STR that does not include
the SEPARATOR string if it appears at the beginning
or end of STR."

  ;; Start off by stripping the SEPARATOR from the end
  ;; of STR, if it is present.
  (let* ((str (strip-end-separator origstr file-name-separator-string))
         (str-len (string-length str))
         (separator-len (string-length separator)))
    (cond
     ((or (zero? str-len)
          (zero? separator-len)
          (< str-len separator-len))
      str)

     ;; Check if SEPARATOR is at the beginning of STR
     ((string= str separator 0 separator-len)
      ;; Return a copy of STR without SEPARATOR
      (substring/read-only str separator-len))
     (else
      str))))

(define (build-filename . elements)
  "Creates a filename by concatenating a series of string elements.  A
filename separator string is placed between the elements when those
elements don't have already them.  If any of the elements is an empty
string, it is ignored."
  (cond
   ((null? elements)
    (error "empty list"))
   ((= 1 (length elements))
    (strip-end-separator (first elements) file-name-separator-string))
   (else
    (fold
     (lambda (suffix prefix)
       ;; Append the string so far with a slash and the next element.
       ;; But if the next element is empty, don't append a slash.
       (string-append
        prefix
        (if (string-null? suffix)
            ""
            file-name-separator-string)
        ;; And strip of any extra slashes from the next element,
        ;; so we won't end up with multiple slashes in a row.
        (strip-separators suffix file-name-separator-string)))

     ;; For the 1st element, only strip extra slashes from the end,
     ;; because it might be an absolute path.
     (strip-end-separator (car elements) file-name-separator-string)
     (cdr elements)))))

(define (file-test-directory? filename)
  (eqv? 'directory (stat:type (stat filename))))

(define (use-windows-separators filename)
  "Replace forward slashes with backward slashes
in FILENAME"
  (let ((str (string-copy filename)))
    (string-for-each-index
     (lambda (i)
       (let ((c (string-ref str i)))
         (string-set! str i
                      (if (eqv? #\/ c)
                          #\\
                          c))))
     str)
    str))

(define (valid-windows-home-dir filename)
  ;; Hopefully FILENAME is valid
  (if (and (absolute-file-name? filename)
           (file-exists? filename)
           (file-test-directory? filename))
      (use-windows-separators filename)
      ;; else, hail mary.
      (string-copy (or (getenv "USERPROFILE")
                       "C:\\Windows"))))


(define (get-system-data-dirs)
  "Returns a list of directories that are the default
data directories."
  (let ((data-dirs-env (getenv "XDG_DATA_DIRS")))
    (unless (and data-dirs-env (not (string-null? data-dirs-env)))
      (set! data-dirs-env "/usr/local/share/:/usr/share/"))
    (string-split data-dirs-env
                  (string-ref (search-path-separator-string) 0))))

(define (get-user-database-dir)
  (passwd:dir (getpwuid (getuid))))

(define (get-home-dir)
  (let ((home-env (getenv "HOME"))
        (osname (utsname:sysname (uname))))
    (cond
     ((string=? osname "Windows")
      (valid-windows-home-dir home-env))
     ((and (file-exists? home-env)
           (file-test-directory? home-env))
      home-env)
     (else
      (get-user-database-dir)))))

(define (get-tmp-dir)
  (let ((temp-env (getenv "TEMP"))
        (tmpdir-env (getenv "TMPDIR"))
        (osname (utsname:sysname (uname))))
    (cond
     ((string=? osname "Windows")
      (if (and temp-env (> (string-length temp-env) 0))
          temp-env
          ;; else
          (get-windows-directory-root)))
     (else
      (if (and tmpdir-env (> (string-length tmpdir-env) 0))
          tmpdir-env
          ;; else
          "/tmp")))))

(define (get-prgname)
  "Returns the name of the program."
  (car (command-line)))

(define (get-user-name)
  "Return the username of the current user."
  (passwd:name (getpwuid (getuid))))

(define (get-user-data-dir)
  "Return a path to the XDG data directory for the current user."
  (let ((env (getenv "XDG_DATA_HOME")))
    (if (and env (not (string-null? env)))
        env
        ;; else
        (build-filename (get-home-dir)
                        ".local"
                        "share"))))

(define (get-user-config-dir)
  "Return a path to the XDG config directory for the current user."
  (let ((env (getenv "XDG_CONFIG_HOME")))
    (if (and env (not (string-null? env)))
        env
        ;; else
        (build-filename (get-home-dir)
                        ".config"))))

(define (get-user-cache-dir)
  "Return a path to the XDG cache directory for the current user."
  (let ((env (getenv "XDG_CACHE_HOME")))
    (if (and env (not (string-null? env)))
        env
        ;; else
        (build-filename (get-home-dir)
                        ".cache"))))

(define (get-user-runtime-dir)
  "Return a path to the XDG runtime directory for the current user."
  (let ((env (getenv "XDG_RUNTIME_HOME")))
    (if (and env (not (string-null? env)))
        env
        ;; else
        (get-user-cache-dir))))

;; Remember read-string is get-file-contents
(define (get-user-special-dir special)
  "Given a string that represents an XDG user directory, such as
\"desktop\", \"documents\", \"download\", \"music\", \"pictures\", or
\"videos\", this routine checks the configuration for the path to that
user directory."
  (let* (;; Open the XDG config file
         (config-file (build-filename (get-user-config-dir)
                                      "user-dirs.dirs"))
         (config-port (open-input-file config-file))

         ;; Construct an XDG directory name from SPECIAL
         (xdg-directory-label (string-append
                               "XDG_"
                               (string-upcase special)
                               "_DIR")))
    (write config-file) (newline)
    (write xdg-directory-label) (newline)
    ;; Loop over each line in "user-dirs.dirs" looking for a match.
    (let loop ((orig-config-entry (read-line config-port)))
      (if (eof-object? orig-config-entry)
          ;; We've reached the end, so give up
          (begin
            (close-port config-port)
            #f)

          ;; Otherwise, let's check this entry
          (let ((config-entry (string-trim-both orig-config-entry)))
            (cond
             ((not (string-prefix? xdg-directory-label config-entry))
              ;; This entry doesn't match, so keep looking
              (loop (read-line config-port)))

             ((string-prefix? xdg-directory-label config-entry)
              ;; We've found a matching line, so get the right-hand side.
              ;; The part that matters is in between the quotation marks.
              (let ((left (string-index config-entry #\"))
                    (right (string-rindex config-entry #\"))
                    (dir ""))
                (if (or (not left) (not right) (= left right))
                    ;; This entry is malformed with regards to
                    ;; quotation marks, so keep looking.
                    (loop (read-line config-port))

                    ;; Otherwise, looks like we found something in
                    ;; quotation marks.
                    (begin
                      (set! dir (substring config-entry (1+ left) right))
                      (cond
                       ((string-prefix? "$HOME/" dir)
                        ;; Return a relative path, dropping $HOME/ and
                        ;; replacing it with the user's home
                        ;; directory.
                        (build-filename (get-home-dir) (string-drop dir 6)))

                       ((string-prefix? "/" dir)
                        ;; Return an absolute path
                        dir)

                       (else
                        ;; This entry is malformed, so keep looking
                        (loop (read-line config-port))))))))))))))

(define (find-data-file filename)
  "Search for FILENAME in the standard data file directories for this user,
using the preferred order for data directories.  Returns the first
matching file discovered, or #f if there is no file by that name in
any of this user's data directories."
  (let ((data-dirs (cons
                    (get-user-data-dir)
                    (get-system-data-dirs))))
    (if (null? data-dirs)
        ;; This is impossible: there is always at least one data dir.
        #f
        ;; Else, search for a candidate matching filename.
        (let loop ((cur-dir (car data-dirs))
                   (rest (cdr data-dirs)))
          (let ((fname (build-filename cur-dir filename)))
            (cond
             ((file-exists? fname)
              fname)
             ((null? rest)
              #f)
             (else
              (loop (car rest) (cdr rest)))))))))

(define %getpagesize
  ;; getpagesize(2) is in the C libraries of GNU/Linux, the BSDs and
  ;; macOS.  Look it up once, through the dynamic FFI.
  (false-if-exception
   (pointer->procedure int (dynamic-func "getpagesize" (dynamic-link)) '())))

(define (getpagesize)
  "Return the size of a memory page in bytes, or #f if it can't be
determined."
  (and %getpagesize (%getpagesize)))
