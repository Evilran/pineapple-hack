namespace Pineapple;

const int TOKEN_EOF         = 0; // end-of-file
const int TOKEN_VAR_PREFIX  = 1; // $
const int TOKEN_LEFT_PAREN  = 2; // (
const int TOKEN_RIGHT_PAREN = 3; // )
const int TOKEN_EQUAL       = 4; // =
const int TOKEN_QUOTE       = 5; // "
const int TOKEN_DUOQUOTE    = 6; // ""
const int TOKEN_NAME        = 7; // Name ::= [_A-Za-z][_0-9A-Za-z]*
const int TOKEN_PRINT       = 8; // print
const int TOKEN_IGNORED     = 9; // Ignored

const dict<int, string> TokenNameMap = dict [
    TOKEN_EOF         => "EOF",
    TOKEN_VAR_PREFIX  => "$",
    TOKEN_LEFT_PAREN  => "(",
    TOKEN_RIGHT_PAREN => ")",
    TOKEN_EQUAL       => "=",
    TOKEN_QUOTE       => "\"",
    TOKEN_DUOQUOTE    => "\"\"",
    TOKEN_NAME        => "Name",
    TOKEN_PRINT       => "print",
    TOKEN_IGNORED     => "Ignored"
];

const dict<string, int> Keywords = dict[ "print" => TOKEN_PRINT ];

class Token {

    public int $lineNum;
    public int $tokenType;
    public string $token;

    public function __construct(int $lineNum = 0, int $tokenType = 0, string $token = '') {
        $this->lineNum   = $lineNum;
        $this->tokenType = $tokenType;
        $this->token     = $token;
    }
}

class Variable {

    public int $lineNum;
    public string $name;

    public function __construct() {

        $this->lineNum   = 0;
        $this->name      = '';
    }
}

interface Statement {}

class AssignmentStatement implements Statement {

    public int $lineNum;
    public Variable $variable;
    public string $string;

    public function __construct() {

        $this->lineNum  = 0;
        $this->variable = new Variable();
        $this->string   = '';
    }
}

class PrintStatement implements Statement {

    public int $lineNum;
    public Variable $variable;

    public function __construct() {

        $this->lineNum  = 0;
        $this->variable = new Variable();
    }
}

class SourceCode {

    public int $lineNum;
    public vec<Statement> $statements;

    public function __construct() {

        $this->lineNum = 0;
        $this->statements = vec[];
    }
}
