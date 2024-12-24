section .data
  err_invalid_data  db "Error: Invalid data", 0
  filename          db "input2", 0

section .bss
  data_buf          resb 2048
  buf_len           equ 2048

  data_len          resq 1
  end_ptr           resq 1

  digit_ptrs        resd 1024

section .text
  global _start

; note that the idea of this program is to be speedy. I'm making assumptions because I already know what the input looks like
; which is to say: this is NOT memory safe lmfao
_start:
  ; open file
  mov rax, 2               ; syscall number for sys_open (2)
  mov rdi, filename        ; pointer to the filename
  mov rsi, 0               ; flags: read-only
  mov rdx, 0               ; mode: not needed for read-only
  syscall

  ; is the file valid?
  test rax, rax
  js error_exit

  mov rdi, rax

  ; read file
  mov rax, 0
  mov rsi, data_buf
  mov rdx, buf_len
  syscall

  ; did it work?
  test rax, rax
  js error_exit

  ; store bytes read for later
  mov [data_len], rax
  lea rax, [rax + rsi]
  mov [end_ptr], rax
  
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
  jb .below_0
  cmp byte [rsi + rcx], 0x39
  jbe .done
  jmp .not_digit

.below_0:
  cmp byte [rsi + rcx], 0x0
  jne .not_digit

.possible_error:
  cmp rax, qword [data_len]
  jbe .not_digit
  mov rsi, err_invalid_data
  jmp error_exit
  
.not_digit:
  inc rcx
  jmp .digit_loop

.done:
  lea rsi, [rsi + rcx]
  pop rcx
  ret

; iterate through the string and push all the '0' strings to the stack
; also grab the width while we're at it
find_zeroes:
  xor rax, rax
  xor rdx, rdx
  xor rcx, rcx
  lea rbx, [rel .first_line_ended]   ; where we will jump when we encounter a newline
  lea rax, [rel climb_recursively]

.find_loop:
  cmp byte [rsi + rcx], 0x30
  ja .next_character
  je .found_zero
  jmp rbx                            ; either endl or null (or bad input)

; the first time this is reached it should be because it is a \n
; but there isn't a meaningful difference if it isn't so I'm not going to check
.first_line_ended:
  mov rdx, rcx
  inc rdx
  lea rbx, [rel .next_character]
  jmp .next_character

.found_zero:
  push 0x30
  lea rdi, [rsi + rcx]
  push rdi
  push rax

.next_character:
  inc rcx
  cmp byte [rsi + rcx], 0x00
  jne .find_loop

  xor rcx, rcx
  ret

climb_recursively:
  pop rsi                     ; pointer to current grid position
  pop rbx                     ; prev value

  ; check in range
  cmp rsi, qword [data_buf]
  jae .end
  cmp rsi, qword [end_ptr]
  jg .end

  ; check the number is one greater than prev
  cmp bl, byte [rsi]
  jne .end

  ; check if this is the top
  cmp byte [rsi], 0x39
  je .top_reached

  inc rbx

  ; right
  push rbx
  mov rax, rsi
  inc rax
  push rax
  lea rax, [rel climb_recursively]
  push rax

  ; left
  push rbx
  mov rax, rsi
  dec rax
  push rax
  lea rax, [rel climb_recursively]
  push rax

  ; 
  push rbx
  mov rax, rsi
  sub rax, rdx
  push rax
  lea rax, [rel climb_recursively]
  push rax


  push rbx
  mov rax, rsi
  add rax, rdx
  push rax
  lea rax, [rel climb_recursively]
  push rax

  jmp .end


.top_reached:
  inc rcx

.end:
  ret
