;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                       User settings                                  ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;"Profile" settings: max-speed (km,h), motor-current
; Kmh get rounded stupidly to m/s
(define profile_1 (list 10 20))
(define profile_2 (list 15 30))
(define profile_3 (list 22 40))
(define profile_S2 (list 100 30))
(define profile_S3 (list 100 90))

;;;Set the id of the other VESC (no, not doing that automatically, for your safety)
(define can_slave_id_list (list 61))


;;;P06 and P07 set in display (important for speed calc)
(define p06 10)
(define p07 30) ;Should be same as magnets in vesc

;;; Combo for two additional modes triggered by light on
(define gear-key [1 2 3 2 3 2 3])
;Stuff below this line is for nerds, don't touch it if you don't know what you are doing
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;UART configuration on COM-Port
;;;Refer to https://github.com/aka13-404/IO-Hawk-Legacy-Info for protocol details
(uart-start 1200)
(define display-packet (bufcreate 16)); No idea why it does not work with 15

(define packet-length 15)

(define esc-packet (bufcreate 15))
(bufset-u8 esc-packet 0 0x36) ;Esc header

;todo - explain in the main docks where the key comes from, explain how it works
(define encoding-key-array [
    0x5e 0x23 0x5c 0x21 0x2a 0x2f 0x28 0x2d 0x26 0x2b 0x24 0x29 0x52 0x57 0x50 0x55
    0x4e 0x53 0x4c 0x51 0x5a 0x5f 0x58 0x5d 0x56 0x5b 0x54 0x59 0x02 0x07 0x00 0x05
    0x3e 0x03 0x3c 0x01 0x0a 0x0f 0x08 0x0d 0x06 0x0b 0x04 0x09 0x32 0x37 0x30 0x35
    0x2e 0x33 0x2c 0x31 0x3a 0x3f 0x38 0x3d 0x36 0x3b 0x34 0x39 0x62 0x67 0x60 0x65
    0x1e 0x63 0x1c 0x61 0x6a 0x6f 0x68 0x6d 0x66 0x6b 0x64 0x69 0x12 0x17 0x10 0x15
    0x0e 0x13 0x0c 0x11 0x1a 0x1f 0x18 0x1d 0x16 0x1b 0x14 0x19 0x42 0x47 0x40 0x45
    0x7e 0x43 0x7c 0x41 0x4a 0x4f 0x48 0x4d 0x46 0x4b 0x44 0x49 0x72 0x77 0x70 0x75
    0x6e 0x73 0x6c 0x71 0x7a 0x7f 0x78 0x7d 0x76 0x7b 0x74 0x79 0x22 0x27 0x20 0x25])

(define encoded-bytes [ 3 4 5 7 8 9 10 11 12 13 ])



;;; Convert human-readable speed into m/s speed
(setix profile_1 0 (/ (ix profile_1 0) 3.6))
(setix profile_2 0 (/ (ix profile_2 0) 3.6))
(setix profile_3 0 (/ (ix profile_3 0) 3.6))
(setix profile_S2 0 (/ (ix profile_S2 0) 3.6))
(setix profile_S3 0 (/ (ix profile_S3 0) 3.6))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                    Debug stuff                                       ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define debug 0)

(defun print-bytes (x)
    (progn
        (var debug-print-packet "")
        (looprange each 0 packet-length
                (setvar 'debug-print-packet (str-merge debug-print-packet (str-from-n (bufget-u8 x each)) " "))
        )
        (print debug-print-packet)
    )
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;       Converting data from vesc for the display functions            ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;Speed display
(defun speed-calc () (* (* p07 (/ (get-speed) (* p06 3.1415 0.0254))) 1.52069))
    ; get m/s, divide by wheel circumference in m to get rotation/s, multiply by magnets
    ;(we are going backwards to something a la erpm), multiply by unknown factor (please help me understand why that factor exists, check excel, run experiments)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;       Converting data from display for the vesc functions            ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Gets gear number and applies changes
;Checks if gears have changed; If they changed, change some modes.
(define last-gear 0)
(define last-light 0)
(define profile_S_switch 0)

(defun gear-calc (gear light)
    (progn
        (if (!= last-gear gear)
            (progn
                (cond
                    ((= gear 5) ; Gear 1
                        (progn ;Here is a list of commands, which get run when profile change to 1
                            (gear-history 1)
                            (set-param 'max-speed (ix profile_1 0) can_slave_id_list)
                            (set-param 'l-current-max (ix profile_1 1) can_slave_id_list)
                            (setvar 'profile_S_switch 0)
                        )
                    )
                    ((= gear 10) ; Gear 2
                        (if (eq profile_S_switch 0) ;Here is a list of commands, which get run when profile change to 2 + S2
                            (progn
                                (gear-history 2)
                                (set-param 'max-speed (ix profile_2 0) can_slave_id_list)
                                (set-param 'l-current-max (ix profile_2 1) can_slave_id_list)
                            )
                            (progn
                                (set-param 'max-speed (ix profile_S2 0) can_slave_id_list)
                                (set-param 'l-current-max (ix profile_S2 1) can_slave_id_list)
                            )
                        )
                    )
                    ((= gear 15) ; Gear 3
                        (if (eq profile_S_switch 0) ;Here is a list of commands, which get run when profile change to 3 + S3
                            (progn
                                (gear-history 3)
                                (set-param 'max-speed (ix profile_3 0) can_slave_id_list)
                                (set-param 'l-current-max (ix profile_3 1) can_slave_id_list)
                            )
                            (progn
                                (set-param 'max-speed (ix profile_S3 0) can_slave_id_list)
                                (set-param 'l-current-max (ix profile_S3 1) can_slave_id_list)
                            )
                        )
                    )
                )
                (setvar 'last-gear gear)
            )

        )
        (if (!= last-light light)
            (progn
                (if (and (eq light 1) (eq gear-key gear-history-array))
                    (progn
                        (setvar 'profile_S_switch 1)
                        (setvar 'last-gear 228)
                        (bufset-u8 esc-packet 4 32)
                    )
                )
                (setvar 'last-light light)
            )
        )
        ;For debug purposes - prints gear history
        ;(print gear-history-array)
    )
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                            Service functions                         ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;; Checksum function
(defun crc-calc (x)
    (progn
    (var crc 0) ; checksum resets each loop
        (looprange each 0 (- packet-length 1)
            (setvar 'crc (bitwise-xor crc (bufget-u8 x each)))
        )
    )
)

;;;Function to set config parameter to local and all specified vescs
(defun set-param (param value can_slave_id_list)
    (progn
        (conf-set param value)
        (loopforeach i can_slave_id_list
            (can-cmd i (str-merge "(conf-set " "'" (sym2str param) " " (str-from-n value) ")"))
        )
    )
)

;;; Function to store last gears selected
(define gear-history-array [1 1 1 1 1 1 1])

(defun gear-history (gear)
    (progn ;Shifts values left, writes last value to the rightmost place
        (loopforeach each (range 6) (bufset-u8 gear-history-array each (bufget-u8 gear-history-array (+ each 1))))
        (bufset-u8 gear-history-array 6 gear)
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                        Reader and Writer                             ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;Writer - writes to display
(defun writer ()
    (progn
        (var counter 0)
        (var enc-key 0)
        (loopwhile t
            (progn
                ;Counter in Byte 1
                (setvar 'counter (bufget-u8 esc-packet 1))
                (if (< counter 255) (bufset-u8 esc-packet 1 (+ counter 1)) (bufset-u8 esc-packet 1 0))

                ;Speed Byte 7 & 8
                (bufset-u16 esc-packet 7 (speed-calc))

                ;Encoding the
                ;Step 1 - get encoding key from table
                (if (< (bufget-u8 esc-packet 1) 128)
                    (setvar 'enc-key (bufget-u8 encoding-key-array (bufget-u8 esc-packet 1)))
                    (setvar 'enc-key (bufget-u8 encoding-key-array (- (bufget-u8 esc-packet 1) 128)))
                )
                ;Step 2 - apply encoding key to every encoded byte, remove everything over 256 (propably should be written more human-friendly)
                (looprange each 0 (buflen encoded-bytes) (bufset-u8 esc-packet (bufget-u8 encoded-bytes each) (mod (+ (bufget-u8 esc-packet (bufget-u8 encoded-bytes each)) enc-key) 256)))

                ;Calculate checksum
                (bufset-u8 esc-packet 14 (crc-calc esc-packet))
                

                (uart-write esc-packet)
                (sleep 0.05);No idea why it is necessary; Breaks
                ;Send packet to display
                (bufclear esc-packet 0 2)

                (yield 150000)
                ;;;Writer end

            )
        )
    )
)

;;;Reader
(defun reader ()
    (loopwhile t
        (progn
            (uart-read-bytes display-packet 1 0)    ;Read first byte
            (if (eq (bufget-u8 display-packet 0) 1)    ;If first byte 1, read one more
                (progn
                    (uart-read-bytes display-packet 1 1)    ;Read second byte
                    (if (eq (bufget-u8 display-packet 1) 3)    ;If second byte 3, read remaining
                        (progn
                             (uart-read-bytes display-packet 13 2)
                             (if (eq (bufget-u8 display-packet 14) (crc-calc display-packet))
                             ;If the remaining has coherent checksum, do stuff:
                                (progn
                                    ;Read gears and lamp status for the gear switcher
                                    (gear-calc (bufget-u8 display-packet 4) (if (= 8 (bitwise-and 8 (bufget-u8 display-packet 9))) 1 0))
                                    (yield 75000)
                                )
                             )
                        )
                    )

                )
            )
        )
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Starts reader and writer
(spawn 150 reader)
(spawn 150 writer)