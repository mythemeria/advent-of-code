%define ENDL 0x0d, 0x0a

section .data
  filename  db "input", 0

section .bss
  data_buf        resb 2048
  graph_buf       resb 2048

  buf_len         equ 2048

  data_len        resd 1
  graph_len       resd 1

  map_width       resd 1
  map_height      resd 1

  trailheads      resd 256

section .text
  global _start

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

  ; save file descriptor
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
  
  ; Close the file
  mov rax, 3                    ; sys_close
  syscall                       ; Call kernel

  call print_data

  call calculate_dimensions
  call generate_graph

  ; Exit program
  mov rax, 60                   ; sys_exit
  xor rdi, rdi                  ; Exit code 0
  syscall                       ; Call kernel

error_exit:
  ; handle error and exit
  mov rax, 60                    ; syscall number for sys_exit (60)
  mov rdx, 1                   ; return code 0
  syscall                        ; make the syscall

print_data:
  mov rax, 1
  mov rdi, 1
  mov rsi, data_buf
  mov rdx, data_len
  syscall
  ret

print_graph:
  mov rax, 1
  mov rdi, 1
  mov rsi, graph_buf
  mov rdx, graph_len
  syscall
  ret

; not reusable btw
calculate_dimensions:
  xor rcx, rcx

.calc_loop:
  cmp byte [data_buf + rcx], 0x0a
  jz .done_width
  inc rcx
  jmp .calc_loop

.done_width:
  mov [map_width], rcx
  mov rax, [data_len]
  inc rcx
  xor rdx, rdx
  div rcx
  mov [map_height], rax
  ret

append_to_graph:
  ; not implemented
  ret

generate_graph:
  ;lea byte [data_]

.generation_loop:
  ; see if we're done
  cmp byte [data_buf + rcx], 0
  js .done_generating

  ; if we haven't reached the null byte

  inc rcx
  jmp .generation_loop

.done_generating:

  ret