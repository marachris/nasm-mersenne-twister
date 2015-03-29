all: testmt

testmt: testmt.o mtwister.o

	ld -m elf_i386 -s -o testmt testmt.o mtwister.o

testmt.o: testmt.asm
	nasm -f elf testmt.asm

mtwister.o: mtwister.asm
	nasm -f elf mtwister.asm

clean:
	rm -f *.o
	rm -f testmt
