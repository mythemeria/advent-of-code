section .data
  err_invalid_data  db "Error: Invalid data", 0
  filename          db "testinput", 0

section .bss
  data_buf          resb 2049
  buf_len           equ 2048

  data_len          resq 1
  data_width        resq 1

section .text
  global _start

; note that the idea of this program is to be speedy. I'm making assumptions because I already know what the input looks like
; which is to say: this is NOT memory safe lmfao
_start:
  ; we actually want to start the string with something other than 0x30-0x39 because that's
  ; my silly way of handling the check left of the top left position
  mov byte [data_buf], 0x0a

  ; open file
  mov rax, 2               ; syscall number for sys_open (2)
  mov rdi, filename        ; pointer to the filename
  mov rsi, 0               ; flags: read-only
  mov rdx, 0               ; mode: not needed for read-only
  syscall

  ; is the file valid?
  test rax, rax
  js error_exit

  ; save file descriptor
  mov rdi, rax

  ; read file
  mov rax, 0
  mov rsi, data_buf + 1
  mov rdx, buf_len
  syscall

  ; did it work?
  test rax, rax
  js error_exit

  ; store bytes read for later
  mov [data_len], rax
  
  ; Close the file
  mov rax, 3                    ; sys_close
  syscall                       ; Call kernel

  call print_data
  call find_first_digit
  call find_zeroes

  ; Exit program
  mov rax, 60                   ; sys_exit
  xor rdi, rdi                  ; Exit code 0
  syscall                       ; Call kernel

; prints error message and quits
; error should be null terminated
; rsi = ptr to error message
exit_with_error_msg:
  xor rdx, rdx
  
.find_str_end:
  cmp byte [rdx + rsi], 0
  jne .find_str_end

  mov rax, 1
  mov rdi, 1
  syscall

error_exit:
  mov rax, 60                    ; syscall number for sys_exit (60)
  mov rdx, 1                   ; return code 0
  syscall                        ; make the syscall

print_data:
  push rax
  push rdi
  push rdx
  mov rax, 1
  mov rdi, 1
  mov rdx, [data_len]
  syscall
  pop rdx
  pop rdi
  pop rax
  ret

; in:
; rsi = ptr to start of string
; out:
; rsi = ptr to first digit ('0'-'9') in string
find_first_digit:
  push rcx
  xor rcx, rcx

.digit_loop:
  cmp byte [rsi + rcx], 0x30
  jl .below_0
  cmp byte [rsi + rcx], 0x39
  jle .done
  jmp .not_digit

.below_0:
  cmp byte [rsi + rcx], 0x0
  jne .not_digit

.possible_error:
  cmp rcx, dword [data_len]
  jle .not_digit
  mov rsi, err_invalid_data
  jmp error_exit
  
.not_digit:
  inc rcx
  jmp .digit_loop

.done:
  lea rsi, [rsi + rcx]
  pop rcx
  ret

; in:
; rsi = ptr to start of string
; rcx = index to start counting backwards from
; out:
; rsi = ptr to first digit ('0'-'9') in string
; rcx = index of last digit
find_last_digit:
  cmp byte [rsi - rcx], 0x30
  jl .below_0
  cmp byte [rsi - rcx], 0x39
  jg .not_digit
  ret

.below_0:
  cmp rcx, 0x0
  jg .not_digit
  mov rsi, err_invalid_data
  jmp error_exit
  
.not_digit:
  dec rcx
  jmp find_last_digit


; iterate through the string and push all the '0' strings to the stack
; also grab the width while we're at it
find_zeroes:
  xor rax, rax
  xor rdx, rdx
  xor rcx, rcx
  lea rbx, [rel .first_line_ended]   ; where we will jump when we encounter a newline

.find_loop:
  cmp byte [rsi + rcx], 0x30
  ja .next_character
  je .found_zero
  jmp rbx                            ; either endl or null (or bad input)

; the first time this is reached it should be because it is a \n
; but there isn't a meaningful difference if it isn't so I'm not going to check
.first_line_ended:
  mov [data_width], rcx
  lea rbx, [rel .next_character]
  jmp .next_character

.found_zero:
  call climb_recursively
  add rax, rdx

.next_character:
  inc rcx
  cmp byte [rsi + rcx], 0x00
  jne .find_loop
  ret

; can be called from any starting point!
; rsi = pointer to null-terminated string ([rsi - 1] = '\n')
; rcx = index into null-terminated string
; returns 1 in rdx if it ended successfully (found a '9')
climb_recursively:
  ; see if we can index up and down without going out of bounds
  cmp rcx, data_width + 2
  ja .check_up
  cmp rcx, data_len - data_width

.check_up:

  