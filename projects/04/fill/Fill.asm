// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel;
// the screen should remain fully black as long as the key is pressed.
// When no key is pressed, the program clears the screen, i.e. writes
// "white" in every pixel;
// the screen should remain fully clear as long as no key is pressed.

// Put your code here.
    @status
    M=-1        // status=0xFFFF
    D=0         // Argument - what to set screen bits to
    @SETSCREEN
    0;JMP

(LOOP)
    @KBD // 定義済みのキーボードの値が入っているアドレス
    D=M  // D = キーボードの文字
    @SETSCREEN
    D;JEQ // キーが押されていなければゼロを表示
    D=-1 // キーが押されていれば全て1を表示

(SETSCREEN)
    @ARG // キーが押されていれば文字、押されていなければ-1が格納されたアドレス
    M=D // 新しい状態
    @status // キーが入ったアドレス
    D=D-M
    @LOOP
    D;JEQ // 新旧のステータスを比較し同じならば再度ループ

    @ARG
    D=M // キーの文字を取得
    @status
    M=D // キーのを納

    @SCREEN // D = スクリーンのアドレス
    D=A // 8Kのメモリマップ 32*256
    @8192 // D = スクリーンのアドレス
    D=D+A
    @i
    M=D // i = スクリーンのアドレス

(SETLOOP)
    @i
    D=M-1
    M=D // スクリーンのアドレス - 1
    @LOOP
    D;JLT

    @status
    D=M
    @i
    A=M
    M=D
    @SETLOOP
    0;JMP
