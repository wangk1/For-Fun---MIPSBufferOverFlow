#stack information
#0-RA
#-4 - local var 1 space
#-8-local var 1 space
#...
#80-local var 1

##PLEASE USE WITH info.txt, the strings stored in info.txt will be the one that will be read in and written to by the program via syscall

.data 0x0000
#status messages
wsucess: .asciiz "PID write sucessful"				#20 bytes, 0
wfail: .asciiz "PID write unsucessful"				#23 bytes, 20
rsucess: .asciiz "PID read sucessful"				#19 bytes, 42	
rfail: .asciiz "PID read unsucessful"				#22 bytes, 61
								#total 0x0000 - 0x0051(81)
#greetings and prompt messages								
greeting: .asciiz "----Hello! Welcome to the database----"	#82-121
prompt: .asciiz "Please Enter the informations      "		#121-156
newline: .asciiz "\n"						#157-158		
entryarrow: .asciiz "--->"					#159-163
pidtag: .asciiz "PID: "						#164-169
positiontage: .asciiz "Position: "				#170-181
notfounderror: .asciiz ". Person not found"			#181-199
canadianwaterskier: .asciiz "Canadian Water Skier  "		#200

.data 0x500							#used for file operation data
filename: .asciiz "info.txt"					#1000-1008

.text 0x3000
main:

ori $s0, $v0, 0							#stores the file buffer in s0

ori $v0, $0, 4							#prints greeting
ori $a0, $0, 82
syscall

ori $v0, $0, 4							#newline
ori $a0, $0, 157
syscall

ori $v0, $0, 4							#prints prompt
ori $a0, $0, 121
syscall

ori $v0, $0, 4							#newline
ori $a0, $0, 157
syscall	

loopback:

ori $v0, $0, 4							#prints arrow: ---->
ori $a0, $0, 159
syscall		

ori $sp, $0, 0x3000						#relocate the stack
addi $sp, $sp, -12						#allocate the stack								

jal readinfo							#calls the function that reads								

j loopback

closeprogram:							#closes program

ori $v0, $0, 10						
syscall

#function return: PID, occupation
readinfo:
addi $sp, $sp, -84						#allocate stack

sw $ra, 80($sp)							#stores the ra

addi $a0, $sp, 0						#gives the location of temp 1 on the stack
ori $v0, $0, 8							#reads the string
addi $a1, $0, 83						#store the string in temp var 1	
syscall

#checks if 0 is put in, meaning to end the program, calls closeprogram:
lb $t0, 0($sp)							#load byte
beq $t0, 48, closeprogram

ori $a0, $sp, 0							#argument for readfile func, the address of the input string

#read the database and compare, returns nothing
jal readfile

lw $ra, 80($sp) 						#loads the ra
addi $sp, $sp, 84						#restore stack

jr $ra								######go back to location in main, location of error, causing RA jump#####

#stack:
#0-RA
#-4-local var 1
#...
#-500-local var 1

#read file function-opens file channel, reads the file into memory
#returns:null, arg: the location of input string read in
readfile:
addi $sp, $sp, -508						#allocate stack

sw $ra, 500($sp)						#stores the ra

ori $t8, $a0, 0							#address where input string arg is stored

#Opens the text file named info.txt-used for reading
ori $a0, $0, 0x500						#loads the filename
ori $a1, $0, 0							#read-only
ori $v0, $0, 13
syscall

#save file descriptor in t9
ori $t9, $v0, 0

#reads all bytes from file
ori $a0, $t9, 0							#file descriptor
ori $a1, $sp, 0							#output buffer
ori $a2, $0, 495						#num char to read
ori $v0, $0, 14							#call read file
syscall

#close the stream
or $a0, $0, $t9							#loads the file descriptor
ori $v0, $0, 16							#closes the file
syscall

#this loop parses the file, looking for a match to the string input with t8
ori $t0, $0, 1							#starting byte offset, starts at 1 cause the first letter is #
ori $t1, $sp, 0							#stores the $sp
ori $t2, $t8, 0							#stores the location of input
ori $t5, $0, 0							#starting input offset

fileparseloop:							#file parsing starts here
								#t3 stores the file byte, temp
								#t4 stores the input byte, temp
								


add $t1, $sp, $t0						#determines which byte of file to read
							
lb $t3, 0($t1)	

add $t2, $t8, $t5						#determines which byte of the input to read

lb $t4, 0($t2)

addi $t0, $t0, 1						#shift the offset t0 to the next byte
addi $t5, $t5, 1						#increment the input byte counter

blt $t3, 10, failed						#if the loaded byte is the file ender, then the input is not found

beq $t3, 36, success						#if $ reached, input is successfully found

bne $t3, $t4, skiptonextname					#if the two bytes are not equal

beq $t3, $t4, fileparseloop					#if the two bytes are equal, keep checking

skiptonextname:							#skips to next #, if one exists

add $t1, $sp, $t0						#next location in file bytes
ori $t5, $0, 0							#reset input bytes

lb $t3, 0($t1)							#load the next byte from file

addi $t0, $t0, 1						#increment t0

beq $t3, 35, fileparseloop					#if # is found
blt $t3, 10, failed						#endoffile

j skiptonextname						#loads the next bytes after #

failed:
#failed message
addi $a0, $0, 61
ori $v0, $0, 4
syscall

ori $a0, $0, 181						#prints reason for failure
ori $v0, $0, 4
syscall

ori $a0, $0, 157						#prints a new line
ori $v0, $0, 4
syscall

j end
success:
ori $a0, $t0, 0							#stores the location of $ in the string
ori $a1, $sp, 0							#stores the stack pointer

jal printinfo							#if the pid is successfully found, print the 

#success Message
addi $a0, $0, 42
ori $v0, $0, 4
syscall

ori $a0, $0, 157						#prints a new line
ori $v0, $0, 4
syscall

end:
lw $ra, 500($sp) 						#loads the ra
addi $sp, $sp, 508						#restore stack

jr $ra								#go back to location in readinf


#inputs the location $, aka a matching name has been found

#stack
#0-local var 1
#...
#-84-local var 1
printinfo:
addi $t8, $a0, 0						#stores location of 1 past $ in t8
ori $t9, $a1, 0							#stores start of read file in t9

addi $sp, $sp, -84						#allocate stack

ori $a0, $0, 164						#prints PID:
ori $v0, $0, 4
syscall

printpid:

add $t0, $t8, $t9						#stores the memory location of next char

#this part reads the pid
lb $t1, 0($t0)
beq $t1, 38, endpidread

addi $t8, $t8, 1						#increment $t0 by 1

addiu $t1, $t1, -48						#convert to decimal from ascii

ori $a0, $t1, 0							#prints the number
ori $v0, $0, 1
syscall

j printpid
				
endpidread:							

ori $a0, $0, 157						#prints a new line
ori $v0, $0, 4
syscall

#beginning of position printing
ori $t2, $0, -1							#keeps track of putting words in the stack, so it can be properly printed later

positionprint:

addi $t8, $t8, 1						#increment $t0 by 1, move beyond the &
add $t0, $t8, $t9						#stores the new memory location of next char
addi $t2, $t2, 1

lb $t1, 0($t0)							#loads the next byte

ble $t1, 10, endpositionprint					#if ascii<=newline, the position string has ended

add $t3, $t2, $sp						#get the address of the stack the byte should be in
sb $t1, 0($t3)							#stores byte in stack

j positionprint

endpositionprint:

add $t3, $t2, $sp						#get the address of the stack the byte should be in
lb $t1, 157($0) 						#load newline
sb $t1, 0($t3)							#puts newline into stack

addi $t2, $t2, 1
add $t3, $t2, $sp						#get the address of the stack the byte should be in
lb $t1, 158($0) 						#load null
sb $t1, 0($t3)							#puts null into stack

ori $a0, $0, 170						#prints Position:
ori $v0, $0, 4
syscall

ori $a0, $sp, 0							#prints the stack
ori $v0, $0, 4
syscall

addi $sp, $sp, 84						#restore stack

jr $ra								#go back to readfile function

.text 0x3248
###The buffer overflow part####
theunconventionaljobchanger:					#approx 3248



addi $sp, $sp, -592						#go back to the place where the textfile read is stored

ori $t0, $0, 0							#gets incremented
	
seeknextposition:						#seeks the next &
#t1 stores temporary load byte address for the file input
#t2 stores the byte loaded

add $t1, $t0, $sp						#load the byte at the location
lb $t2, 0($t1)		

beq $t2, 38, replaceposition					#when & is found
blt $t2, 10, storesinfile					#end of the fileinput

addi $t0, $t0, 1						#increment t0

j seeknextposition

replaceposition:						#replace the job description with canadian water skier
ori $t3, $0, 0							#used for canadian water skier loop
ori $t4, $0, 0							#used to store the canadian water skier memeory address

replaceloop:

addi $t0, $t0, 1						#increment t0

add $t1, $t0, $sp

lb $t2, 0($t1)							#load bytes from the file input

ble $t2, 10, seeknextposition					#if the next line is reached, aka end of the position description

addi $t4, $t3, 200						#location of byte in canadian water skier

lb $t2, 0($t4)

beq $t2, 0, padwithspace

sb $t2, 0($t1)

addi $t3, $t3, 1						#increment the memory location of canadian water skier by 1 byte

j replaceloop

padwithspace:							#if canadian water skier is not big enough for the postion space

lb $t2, 208($0)

sb $t2, 0($t1)

j replaceloop

storesinfile:							#stores the data in the txt file

#Opens the text file named info.txt-used for writing
ori $a0, $0, 0x500						#loads the filename
ori $a1, $0, 1							#wite-only
ori $v0, $0, 13
syscall

ori $t0, $v0, 0 						#stores file descriptor

#writes in the file
ori $a0, $t0, 0							#loads the filedescriptor
ori $a1, $sp, 0							#wite-only
ori $a2, $0, 495
ori $v0, $0, 15
syscall

#close the stream
or $a0, $0, $t0							#loads the file descriptor
ori $v0, $0, 16							#closes the file
syscall

endu:

addi $sp, $sp, 592						#go back to the place where the textfile read is stored

j loopback							#back to main
