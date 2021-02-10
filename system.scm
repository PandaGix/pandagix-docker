;; src/system.scm
;; ==============
;;
;; Copying
;; -------
;;
;; Copyright (c) 2020 guixsd authors.
;;
;; This file is part of the *guixsd* project.
;;
;; guixsd is a free software project. You can redistribute it and/or
;; modify if under the terms of the MIT License.
;;
;; This software project is distributed *as is*, WITHOUT WARRANTY OF ANY
;; KIND; including but not limited to the WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE and NONINFRINGEMENT.
;;
;; You should have received a copy of the MIT License along with
;; guixsd. If not, see <http://opensource.org/licenses/MIT>.
;;
(use-modules (gnu))
(use-modules (gnu services))

(use-package-modules bash less linux nvi)


(operating-system
 (host-name "PandaGixDocker")
 (locale "en_US.utf8")
 (timezone "UTC")

 (bootloader (bootloader-configuration
              (bootloader grub-efi-bootloader)
              (target "noop")))

 (file-systems (list (file-system
                      (device "noop")
                      (mount-point "/")
                      (type "noop"))))

 (firmware '())

 (packages (list bash-minimal
                 coreutils-minimal
                 findutils
                 grep
                 less
                 nvi
                 procps
                 sed
                 tar))

 (services (list
            ;; Install special files system wide.
            (service special-files-service-type
                     `(("/bin/sh" ,(file-append (canonical-package bash-minimal)
                                                "/bin/sh"))
                       ("/usr/bin/env" ,(file-append (canonical-package coreutils-minimal)
                                                     "/bin/env"))))
            ;; Disable ``chroot`` usage for the Guix daemon which requires
            ;; a privileged container.
            (service guix-service-type
                     (guix-configuration
                      (extra-options (list "--disable-chroot")))))))
