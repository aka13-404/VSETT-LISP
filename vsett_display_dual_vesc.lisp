;;;P06 and P07 set in display (important for speed calc)
(define p06 10)
(define p07 28)

;;;UART configuration on COM-Port
;;;Refer to https://github.com/aka13-404/IO-Hawk-Legacy-Info for protocol details
(uart-start 1200)
(define display-packet (array-create type-byte 16)); No idea why it does not work with 15
(define packet-length 15)

(define esc-packet (array-create type-byte 15))
(bufset-u8 esc-packet 0 0x36) ;Esc header

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



;;;debug
(define debug 0)

(defun print-bytes (x) 
    ;;If I have to write that again just to print a byte array I don't know what I am going to do
    (progn
        (setvar 'debug-print-packet "")
        (looprange each 0 packet-length
                (setvar 'debug-print-packet (str-merge debug-print-packet (str-from-n (bufget-u8 x each)) " "))
        )
        (print debug-print-packet)
    )
)
;;;debug end



;;;Speed display
(defun speed-calc () (* (* p07 (/ (get-speed) (* p06 3.1415 0.0254))) 1.52069))
    ; get m/s, divide by wheel circumference in m to get rotation/s, multiply by magnets 
    ;(we are going backwards to something a la erpm), multiply by unknown factor (please help me understand why that factor exists, check excel, run experiments)
 

;Calculate bitwise xor for all bytes
(defun crc-calc (x)
    (progn
        (setvar 'crc 0)
        (looprange each 0 (- packet-length 1)
            (setvar 'crc (bitwise-xor crc (bufget-u8 x each)))
        )
    )
)
        


;;; UART reader - reads data from display.

(defun reader ()
    (loopwhile t
        (progn
            (uart-read-bytes display-packet packet-length 0)
            ;(if (= debug 1) (print-bytes display-packet)); print received packet if debug on
            (if (and (eq (bufget-u8 display-packet 0) 1)
                     (eq (bufget-u8 display-packet 1) 3)
                     (eq (bufget-u8 display-packet 14) (crc-calc display-packet))
                );Byte0 = 1, Byte1 = 3, Checksum bitwise xor 0-13 byte
                (progn
                    ;(print "Packet received, everything good")
                )
                (uart-read-bytes display-packet 1 0) ;Else: skip 1 byte forward
            )
        )
    )
)
            

;;; UART writer - writes data to display                        
            
(defun writer ()
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
                
            (if (= debug 1) (print enc-key))
            (if (= debug 1) (print-bytes esc-packet))
            (uart-write esc-packet)
            (bufclear esc-packet 0 2)
            (yield 450000)
        )
    )
)


(spawn 150 reader)
(spawn 150 writer) 
