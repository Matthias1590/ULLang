ul: ./src/ul.asm
	nasm -felf64 -o ./bin/ul.o ./src/ul.asm
	ld -o ./bin/ul ./bin/ul.o

prog: ./out/out.asm
	nasm -felf64 -o ./out/out.o ./out/out.asm
	ld -o ./out/out ./out/out.o

clean:
	rm ./bin/*
