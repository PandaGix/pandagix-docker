(define-module (gix system pandagixdocker)
  #:use-module (gnu)
  #:use-module (gnu system)
  #:use-module (gnu bootloader u-boot)
  #:use-module (guix gexp)
  #:use-module (guix store)
  #:use-module (guix monads)
  #:use-module (guix modules)
  #:use-module ((guix packages) #:select (package-version))
  #:use-module ((guix store) #:select (%store-prefix))
  #:use-module (gnu installer)
  #:use-module (gnu system locale)
  #:use-module (gnu services)
  #:use-module (gnu services avahi)
  #:use-module (gnu services dbus)
  #:use-module (gnu services networking)
  #:use-module (gnu services shepherd)
  #:use-module (gnu services ssh)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages bootloaders)
  #:use-module (gnu packages certs)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages linux) ; might conflict with (nongnu packages linux)
  #:use-module (gnu packages package-management)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages xorg)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-26)
  ;;;;added for docker
  #:use-module (gnu packages less)
  #:use-module (gnu packages nvi)
  ;;;;added for non-libre linux
  ;;#:use-module (nongnu packages linux) ; channel inferior
  ;;#:use-module (nongnu system linux-initrd)
  #:use-module (srfi srfi-1)
  #:use-module (guix channels) 
  #:use-module (guix inferior)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages disk)
  #:use-module (gnu packages chromium)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages ibus)
  #:use-module (gnu packages wget)
  ;;(use-service-modules desktop networking ssh xorg)
  #:use-module (gnu services base)
  #:use-module (gnu services desktop)
  #:use-module (gnu services xorg)

  #:export (pandagix-docker)
) ; end of (define module

;;;; start of the docker-os
(define pandagix-docker
(operating-system
  (host-name "PandaGixDocker")
  (locale "en_US.utf8")
  (timezone "UTC")
  (name-service-switch %mdns-host-lookup-nss)
  
  (bootloader (bootloader-configuration
              (bootloader grub-efi-bootloader)
              (target "noop")))

  (file-systems (list (file-system
                      (device "noop")
                      (mount-point "/")
                      (type "noop"))))

  (firmware '())
  (packages (list bash coreutils glibc
                  findutils grep less nvi procps sed tar
                  nss-certs git wget ))

)) ; end of (define (operating-system 
;;;; feed guix directly
pandagix-docker
