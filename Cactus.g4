grammar Cactus;

@members {
	int labelCount = 0;
	String newLabel() {
		labelCount ++;
		return (new String("L")) + Integer.toString(labelCount);
	} 
}

// Parser Rules
program locals [int reg = 0]: 
    PROGRAM BEGIN {
        System.out.println("\t"+".data");
    }
    declarations {
        System.out.println("\t"+".text");
        System.out.println("main:");
    }
    statements[$reg] END;

declarations: declarations VAR ID {
		System.out.println($ID.text+":\n\t.word\t0");
	} |;

statements [int reg]: statement[$reg] statements[$reg] |;

statement [int reg]:
    READ ID {
        System.out.println("\tli\t\$v0, 5");
		System.out.println("\tsyscall");
		System.out.println("\tla\t\$t"+$reg+", "+$ID.text);
		System.out.println("\tsw\t\$v0, 0(\$t"+$reg+")");
    } 
    | SET ID '=' arithmeticExpression[$reg] {
        System.out.println("\tla\t\$t"+$arithmeticExpression.nreg+", "+$ID.text);
		System.out.println("\tsw\t\$t"+$arithmeticExpression.place+", 0(\$t"+$arithmeticExpression.nreg+")");
    }
    | WRITE arithmeticExpression[$reg] {
        System.out.println("\tmove\t\$a0, \$t"+$arithmeticExpression.place);
		System.out.println("\tli\t\$v0, 1");
		System.out.println("\tsyscall");
    } 
    | IF {
        String b_true = newLabel();
        String b_false = newLabel();
    } booleanExpression[$reg, b_true, b_false] THEN {
        System.out.println(b_true+":\t\t\t# Then");
    } statements[$reg] elseStatement[$reg, b_false] ENDIF
    | WHILE {
        String w_begin = newLabel();
        String w_do = newLabel();
        String w_end = newLabel();
        System.out.println(w_begin+":\t\t\t# While");
    } booleanExpression[$reg, w_do, w_end] DO {
        System.out.println(w_do+":\t\t\t# Do");
    } statements[$reg] ENDWHILE {
        System.out.println("\tb\t"+w_begin);
        System.out.println(w_end+":\t\t\t# EndWhile");
    }
    | EXIT {
        System.out.println("\tli\t\$v0, 10");
		System.out.println("\tsyscall");
    };

elseStatement [int reg, String b_false]
    : ELSE {
        String b_endif = newLabel();
        System.out.println("\tb\t"+b_endif);
        System.out.println($b_false+":\t\t\t# Else");
    } statements[$reg] {
        System.out.println(b_endif+":\t\t\t# EndIf");
    } | {
        System.out.println($b_false+":\t\t\t# EndIf");
    };

booleanExpression[int reg , String b_true , String b_false] returns [int nreg]
    : booleanTerm[$reg , $b_true , $b_false] {
        System.out.println("\t\$t"+($booleanTerm.nreg-1)+", \$t"+$booleanTerm.nreg+", "+$b_true);
    } (booleanExpression1[$booleanTerm.nreg-1 , $b_true , $b_false]) {
        System.out.println("\tb\t"+$b_false);
    };

booleanExpression1[int reg , String b_true , String b_false] returns [int nreg]
    : {
        String or_label = newLabel();
        System.out.println("\tb\t"+or_label); 
		System.out.println(or_label+":"); 
    } OR booleanTerm[$reg , $b_true , $b_false] booleanExpression1[$reg , $b_true, $b_false] {
        System.out.println("\t\$t0"+", \$t1"+", "+$b_true);
    } | {
        $nreg = $reg;
    };

booleanTerm[int reg , String b_true , String b_false] returns [int nreg]
    : booleanFactor[$reg , $b_true , $b_false]
    (booleanTerm1[$booleanFactor.nreg , $b_true , $b_false]) {
        $nreg = $booleanTerm1.nreg;
    };

booleanTerm1[int reg , String b_true , String b_false] returns [int nreg]
    : {
        String and_label = newLabel();
        System.out.println("\t\$t"+($reg-1)+", \$t"+$reg+", "+and_label);
        System.out.println("\tb\tL"+$b_false); 
		System.out.println(and_label+":");
    } AND booleanFactor[$reg-1 , $b_true , $b_false] booleanTerm1[$booleanFactor.nreg , $b_true , $b_false] {
        $nreg = $booleanTerm1.nreg;
    } | {
        $nreg = $reg;
    };

booleanFactor[int reg , String b_true , String b_false] returns [int nreg]
    : NOT booleanFactor[$reg , $b_false , $b_true] {
        $nreg = $booleanFactor.nreg;
    }
    | relationExpression[$reg , $b_true , $b_false] {
        $nreg = $relationExpression.nreg;
    };

relationExpression[int reg , String b_true , String b_false] returns [int nreg]
    : a=arithmeticExpression[$reg] relation_op b=arithmeticExpression[$a.nreg] {
    System.out.print("\t"+$relation_op.op);
    $nreg = $a.nreg;
    };

relation_op returns [String op]
    :'==' {$op = "beq";}
    | '<>' {$op = "bne";} 
    | '>' {$op = "bgt";} 
    | '>=' {$op = "bge";} 
    | '<' {$op = "blt";} 
    | '<=' {$op = "ble";}
    ;

arithmeticExpression [int reg] returns [int nreg , int place]
    : arithmeticTerm[$reg] arithmeticExpression1[$arithmeticTerm.nreg , $arithmeticTerm.place] {
        $nreg = $arithmeticExpression1.nreg;
        $place = $arithmeticExpression1.place;
    };

arithmeticExpression1 [int reg , int s_place] returns [int nreg , int place]
    : ADD arithmeticTerm[$reg] {
        System.out.println("\tadd\t\$t"+$s_place+", \$t"+$s_place+", \$t"+$arithmeticTerm.place);
    } ae = arithmeticExpression1[$arithmeticTerm.nreg , $s_place] {
        $nreg = $ae.nreg;
        $place = $ae.place;
    }
    | SUB arithmeticTerm[$reg] {
        System.out.println("\tsub\t\$t"+$s_place+", \$t"+$s_place+", \$t"+$arithmeticTerm.place);
    } ae = arithmeticExpression1[$arithmeticTerm.nreg , $s_place] {
        $nreg = $ae.nreg;
        $place = $ae.place;
    }
    | {
        $nreg = $reg;
        $place = $s_place;
    };

arithmeticTerm [int reg] returns [int nreg , int place]
    : arithmeticFactor[$reg] arithmeticTerm1[$arithmeticFactor.nreg , $arithmeticFactor.place] {
        $nreg = $arithmeticTerm1.nreg;
        $place = $arithmeticTerm1.place;
    };

arithmeticTerm1 [int reg , int s_place] returns [int nreg , int place]
    : {
        $nreg = $reg;
        $place = $s_place;
    }
    | MUL arithmeticFactor[$reg] {
        System.out.println("\tmul\t\$t"+$s_place+", \$t"+$s_place+", \$t"+$arithmeticFactor.place);    
    } at = arithmeticTerm1[$arithmeticFactor.place, $s_place] {
        $nreg = $at.nreg;
        $place = $at.place;
    }
    | DIV arithmeticFactor[$reg] {
        System.out.println("\tdiv\t\$t"+$s_place+", \$t"+$s_place+", \$t"+$arithmeticFactor.place);
        System.out.println("\tmflo\t\$t"+$s_place);
    } at = arithmeticTerm1[$arithmeticFactor.place, $s_place] {
        $nreg = $at.nreg;
        $place = $at.place;
    }
    | MOD arithmeticFactor[$reg] {
        System.out.println("\tdiv\t\$t"+$s_place+", \$t"+$s_place+", \$t"+$arithmeticFactor.place);
        System.out.println("\tmfhi\t\$t"+$s_place);
    } at = arithmeticTerm1[$arithmeticFactor.place, $s_place] {
        $nreg = $at.nreg;
        $place = $at.place;
    };

arithmeticFactor [int reg] returns [int nreg , int place]
    : '-' a=arithmeticFactor[$reg] {
        System.out.println("\tneg\t\$t"+$a.place+", \$t"+$a.place);
        $nreg = $a.nreg;
        $place = $a.place;
    }
    | primaryExpression[$reg] {
        $nreg = $primaryExpression.nreg;
        $place = $primaryExpression.place;
    };

primaryExpression [int reg] returns [int nreg , int place]
    : CONST {
        System.out.println("\tli\t\$t"+$reg+", "+$CONST.text);
		$nreg = $reg + 1;
		$place = $reg;
    }
    | ID {
        System.out.println("\tla\t\$t"+$reg+", "+$ID.text);
		System.out.println("\tlw\t\$t"+$reg+", 0(\$t"+$reg+")");
		$nreg = $reg + 1;
		$place = $reg;
    }
    | '(' arithmeticExpression[$reg] ')' {
        $nreg = $arithmeticExpression.nreg;
        $place = $arithmeticExpression.place;
    };


/* lexer rules */
PROGRAM : 'Program' ;
AND   : 'And' ;
BEGIN : 'Begin' ;
DO    : 'Do' ;
ELSE  : 'Else' ;
END   : 'End' ;
ENDIF : 'EndIf' ;
ENDWHILE : 'EndWhile' ;
EXIT  : 'Exit' ;
IF    : 'If' ;
SET   : 'Set' ;
NOT   : 'Not' ;
OR    : 'Or' ;
READ  : 'Read' ;
THEN  : 'Then' ;
VAR   : 'Var' ;
WHILE : 'While' ;
WRITE : 'Write' ;

// Operators
ADD    : '+' ;
SUB    : '-' ;
MUL    : '*' ;
DIV    : '/' ;
MOD    : '%' ;
ASSIGN : '=' ;
EQ     : '==' ;
ANGLE  : '<>' ;
GT     : '>' ;
GTE    : '>=' ;
LT     : '<' ;
LTE    : '<=' ;
LPAREN : '(' ;
RPAREN : ')' ;

// Identifiers and constants
ID     : [a-zA-Z_][a-zA-Z0-9_]* ;
CONST  : [0-9]+ ;

// Whitespace and comments
WS     : [ \t\r\n]+ -> skip ;
COMMENT : '//' ~[\r\n]* -> skip ;

