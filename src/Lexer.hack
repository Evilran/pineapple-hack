namespace Pineapple;

use namespace HH\Shape;
use namespace HH\Lib\{C,Str,Regex};
use type HH\Lib\Regex\Pattern;

class Lexer {
    
    private string $sourceCode;
    private int $lineNum;
    private string $nextToken;
    private int $nextTokenType;
    private int $nextTokenLineNum;

    public function __construct(string $sourceCode) {

        $this->sourceCode         = $sourceCode;
        $this->lineNum            = 1; // start at line 1 in default.
        $this->nextToken          = "";
        $this->nextTokenType      = TOKEN_EOF;
        $this->nextTokenLineNum   = 0;
    }

    public function getLineNum(): int {

        return $this->lineNum;
    }

    public function nextTokenIs(int $tokenType): Token {

        $nowToken = $this->getNextToken();
        // syntax error
        if ($tokenType != $nowToken->tokenType) {
            $err = Str\format(
                "NextTokenIs(): syntax error near '%d', expected token: {%s} but got {%s}.",
                $nowToken->lineNum,
                TokenNameMap[$tokenType],
                TokenNameMap[$nowToken->tokenType]
            );
            throw new \Exception($err);
        }
        return $nowToken;
    }

    public function lookAheadAndSkip(int $expectedType): void {

        // get next token
        $nowLineNum = $this->lineNum;
        $nextToken = $this->getNextToken();
        // not is expected type, reverse cursor
        if ($nextToken->tokenType != $expectedType) {
            $this->lineNum          = $nowLineNum;
            $this->nextTokenLineNum = $nextToken->lineNum;
            $this->nextTokenType    = $nextToken->tokenType;
            $this->nextToken        = $nextToken->token;
        }
    }

    public function lookAhead(): int {

        // $this->nextToken already setted
        if ($this->nextTokenLineNum > 0) {
            return $this->nextTokenType;
        }
        // set it
        $nowLineNum                 = $this->lineNum;
        $nexrToken                  = $this->getNextToken();
        $this->lineNum              = $nowLineNum;
        $this->nextTokenLineNum     = $nexrToken->lineNum;
        $this->nextTokenType        = $nexrToken->tokenType;
        $this->nextToken            = $nexrToken->token;
        return $nexrToken->tokenType;
    }

    private function nextSourceCodeIs(string $s): bool {

        return Str\starts_with($this->sourceCode, $s);
    }

    private function skipSourceCode(int $n): void {

        $this->sourceCode = Str\slice($this->sourceCode, $n);
    }

    private function isIgnored(): bool {

        $isIgnored = false;
        // target pattern
        $isNewLine = (string $c): bool ==> $c == "\r" || $c == "\n";
        $isWhiteSpace = (string $c): bool ==> {
            switch ($c) {
                case "\t":
                case "\n":
                case "\v":
                case "\f":
                case "\r":
                case " ":
                    return true;
            }
            return false;
        };
        // matching
        while (Str\length($this->sourceCode) > 0) {
            if ($this->nextSourceCodeIs("\r\n") || $this->nextSourceCodeIs("\n\r")) {
                $this->skipSourceCode(2);
                $this->lineNum++;
                $isIgnored = true;
            } elseif ($isNewLine($this->sourceCode[0])) {
                $this->skipSourceCode(1);
                $this->lineNum++;
                $isIgnored = true;
            } elseif ($isWhiteSpace($this->sourceCode[0])) {
                $this->skipSourceCode(1);
                $isIgnored = true;
            } else {
                break;
            }
        }
        return $isIgnored;
    }

    private function scan(Pattern<shape(...)> $regExp): string {

        $match = Regex\every_match($this->sourceCode, $regExp);
        invariant(C\count($match) != 0, "Unreachable!");
        $token = (string)Shapes::toArray($match[0])[0];
        $this->skipSourceCode(Str\length($token));
        return $token;
    }

    // return content before token
    public function scanBeforeToken(string $token): string {

        $s = Str\split($this->sourceCode, $token);
        invariant(C\count($s) >= 2, "Unreachable!");
        $this->skipSourceCode(Str\length($s[0]));
        return $s[0];
    }

    private function scanName(): string {

        return $this->scan(re"/^[_\d\w]+/");
    }

    public function getNextToken(): Token {

        // next token already loaded
        if ($this->nextTokenLineNum > 0) {
            $token                  = new Token();
            $token->lineNum         = $this->nextTokenLineNum;
            $token->tokenType       = $this->nextTokenType;
            $token->token           = $this->nextToken;
            $this->lineNum          = $this->nextTokenLineNum;
            $this->nextTokenLineNum = 0;
            return $token;
        }
        return $this->matchToken();
    }

    public function matchToken(): Token {

        // check ignored
        if ($this->isIgnored()) {
            return new Token($this->lineNum, TOKEN_IGNORED, TokenNameMap[TOKEN_IGNORED]);
        }
        // finish
        if (Str\length($this->sourceCode) == 0) {
            return new Token($this->lineNum, TOKEN_EOF, TokenNameMap[TOKEN_EOF]);
        }
        // check token
        switch ($this->sourceCode[0]) {
            case '$':
                $this->skipSourceCode(1);
                return new Token($this->lineNum, TOKEN_VAR_PREFIX, TokenNameMap[TOKEN_VAR_PREFIX]);
            case '(':
                $this->skipSourceCode(1);
                return new Token($this->lineNum, TOKEN_LEFT_PAREN, TokenNameMap[TOKEN_LEFT_PAREN]);
            case ')':
                $this->skipSourceCode(1);
                return new Token($this->lineNum, TOKEN_RIGHT_PAREN, TokenNameMap[TOKEN_RIGHT_PAREN]);
            case '=':
                $this->skipSourceCode(1);
                return new Token($this->lineNum, TOKEN_EQUAL, TokenNameMap[TOKEN_EQUAL]);
            case '"':
                if ($this->nextSourceCodeIs("\"\"")) {
                    $this->skipSourceCode(2);
                    return new Token($this->lineNum, TOKEN_DUOQUOTE, TokenNameMap[TOKEN_DUOQUOTE]);
                }
                $this->skipSourceCode(1);
                return new Token($this->lineNum, TOKEN_QUOTE, TokenNameMap[TOKEN_QUOTE]);
        }
        // check multiple character token
        if ($this->sourceCode[0] == '_' || $this->isLetter($this->sourceCode[0])) {
            $token = $this->scanName();
            if (isset(Keywords[$token])) {
                return new Token($this->lineNum, Keywords[$token], $token);
            } else {
                return new Token($this->lineNum, TOKEN_NAME, $token);
            }
        }

        $err = Str\format("MatchToken(): unexpected symbol near '%s'.", $this->sourceCode[0]);
        throw new \Exception($err);
    }

    private function isLetter(string $c): bool {

        return $c >= 'a' && $c <= 'z' || $c >= 'A' && $c <= 'Z';
    }
}
