/**
Copyright: Copyright (c) 2017 Andrey Penechko.
License: $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0).
Authors: Andrey Penechko.
*/
module test.add;

void testAdd()
{
	import utils;
	import test.utils;

	// Add reg8, reg8
	foreach (Register regA; Register.min..RegisterMax) testCodeGen.addb(regA, Register.min);
	foreach (Register regB; Register.min..RegisterMax) testCodeGen.addb(Register.min, regB);
	assertHexAndReset("00C000C100C200C34000C44000C54000C64000C74100C04100C14100C24100C34100C44100C54100C64100C700C000C800D000D84000E04000E84000F04000F84400C04400C84400D04400D84400E04400E84400F04400F8");

	// Add reg16, reg16
	foreach (Register regA; Register.min..RegisterMax) testCodeGen.addw(regA, Register.min);
	foreach (Register regB; Register.min..RegisterMax) testCodeGen.addw(Register.min, regB);
	assertHexAndReset("6601C06601C16601C26601C36601C46601C56601C66601C7664101C0664101C1664101C2664101C3664101C4664101C5664101C6664101C76601C06601C86601D06601D86601E06601E86601F06601F8664401C0664401C8664401D0664401D8664401E0664401E8664401F0664401F8");

	// Add reg32, reg32
	foreach (Register regA; Register.min..RegisterMax) testCodeGen.addd(regA, Register.min);
	foreach (Register regB; Register.min..RegisterMax) testCodeGen.addd(Register.min, regB);
	assertHexAndReset("01C001C101C201C301C401C501C601C74101C04101C14101C24101C34101C44101C54101C64101C701C001C801D001D801E001E801F001F84401C04401C84401D04401D84401E04401E84401F04401F8");

	// Add reg64, reg64
	foreach (Register regA; Register.min..RegisterMax) testCodeGen.addq(regA, Register.min);
	foreach (Register regB; Register.min..RegisterMax) testCodeGen.addq(Register.min, regB);
	assertHexAndReset("4801C04801C14801C24801C34801C44801C54801C64801C74901C04901C14901C24901C34901C44901C54901C64901C74801C04801C84801D04801D84801E04801E84801F04801F84C01C04C01C84C01D04C01D84C01E04C01E84C01F04C01F8");

	// Add reg8, imm8
	foreach (Register regA; Register.min..RegisterMax) testCodeGen.addb(regA, Imm8(0x24));
	assertHexAndReset("80C02480C12480C22480C3244080C4244080C5244080C6244080C7244180C0244180C1244180C2244180C3244180C4244180C5244180C6244180C724");

	// Add reg16, imm8
	foreach (Register regA; Register.min..RegisterMax) testCodeGen.addw(regA, Imm8(0x24));
	assertHexAndReset("6683C0246683C1246683C2246683C3246683C4246683C5246683C6246683C724664183C024664183C124664183C224664183C324664183C424664183C524664183C624664183C724");

	// Add reg32, imm8
	foreach (Register regA; Register.min..RegisterMax) testCodeGen.addd(regA, Imm8(0x24));
	assertHexAndReset("83C02483C12483C22483C32483C42483C52483C62483C7244183C0244183C1244183C2244183C3244183C4244183C5244183C6244183C724");

	// Add reg64, imm8
	foreach (Register regA; Register.min..RegisterMax) testCodeGen.addq(regA, Imm8(0x24));
	assertHexAndReset("4883C0244883C1244883C2244883C3244883C4244883C5244883C6244883C7244983C0244983C1244983C2244983C3244983C4244983C5244983C6244983C724");

	// Add reg16, imm16
	foreach (Register regA; Register.min..RegisterMax) testCodeGen.addw(regA, Imm16(0x2436));
	assertHexAndReset("6681C036246681C136246681C236246681C336246681C436246681C536246681C636246681C73624664181C03624664181C13624664181C23624664181C33624664181C43624664181C53624664181C63624664181C73624");

	// Add reg32, imm32
	foreach (Register regA; Register.min..RegisterMax) testCodeGen.addd(regA, Imm32(0x24364758));
	assertHexAndReset("81C05847362481C15847362481C25847362481C35847362481C45847362481C55847362481C65847362481C7584736244181C0584736244181C1584736244181C2584736244181C3584736244181C4584736244181C5584736244181C6584736244181C758473624");

	// Add reg64, imm64
	foreach (Register regA; Register.min..RegisterMax) testCodeGen.addq(regA, Imm32(0x24364758));
	assertHexAndReset("4881C0584736244881C1584736244881C2584736244881C3584736244881C4584736244881C5584736244881C6584736244881C7584736244981C0584736244981C1584736244981C2584736244981C3584736244981C4584736244981C5584736244981C6584736244981C758473624");
}
