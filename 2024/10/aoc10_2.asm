; nasm -f elf64 -o aoc10_2.o aoc10_2.asm && ld -o aoc10_2 aoc10_2.o && ./aoc10_2

section .data
  err_invalid_data  db "Error: Invalid data", 0
  err_nomem         db "Error: Ran out of memory. Increase the array size.", 0
  filename          db "input2", 0
  output            times 1024 db 0

section .bss
  data_buf          resb 2048
  buf_len           equ 2048

  data_len          resd 1
  end_ptr           resd 1

  digit_ptrs         resd 256

  jmp_ptr           resd 1
  row_width         resd 1

  total_trailheads  resd 1

section .text
  global _start
  global append_to_array_if_not_in_array

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
  lea rax, [rax + rsi]
  mov [end_ptr], rax
  
  ; Close the file
  mov rax, 3                    ; sys_close
  syscall                       ; Call kernel

  mov dword [total_trailheads], 0
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






find_zeroes:
  xor rax, rax
  xor rcx, rcx
  mov dword [row_width], 0

.find_loop:
  cmp byte [rsi + rcx], 0x30
  ja .next_character
  je .found_zero

  cmp dword [row_width], 0
  je .next_character
  push rcx
  inc rcx
  mov dword [row_width], ecx
  pop rcx

.found_zero:
  lea rax, [rsi + rcx]
  push rax
  push count_nines

.next_character:
  inc rcx
  cmp byte [rsi + rcx], 0x00
  jne .find_loop
  ret



count_nines:
  xor rax, rax
  xor rcx, rcx
  pop rsi
  lea rdi, [digit_ptrs]

.continue:
  cmp rcx, 9
  jae .done



  inc rcx

.done:
  ret


put_surrounding_in_array:
  mov eax, esi




; in:
; rdi = null terminated array to append to
; eax = value to find in array
append_to_array_if_not_in_array:
  push rcx
  xor rcx, rcx
  shl rax, 32
  mov eax, 0

.continue:
  cmp rcx, 255
  jae .error_out
  cmp dword [rdi + rcx], 0
  je .not_in_array
  cmp dword [rdi + rcx], eax
  je .end
  inc rcx
  jmp .continue

.error_out:
  mov rsi, [err_nomem]
  call error_exit

.not_in_array:
  mov qword [rdi + rcx], rax

.end:
  pop rcx
  ret

