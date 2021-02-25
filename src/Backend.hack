namespace Pineapple;

use namespace HH\Lib\{C,Str,IO};

class Backend {

    private SourceCode           $ast;
    private dict<string, string> $globalVar;

    public function __construct() {

        $this->ast = new SourceCode();
        $this->globalVar = dict[];
    }

    public function execute(string $sourceCode): void {

        $parser          = new Parser($sourceCode);
        $this->ast       = $parser->parse();
        $this->resolveAST();
    }

    private function resolveAST(): void {

        invariant(C\count($this->ast->statements) != 0, "resolveAST(): no code to execute, please check your input.");

        foreach ($this->ast->statements as $statement) {
            $this->resolveStatement($statement);
        }
    }

    private function resolveStatement(Statement $statement): void {

        if ($statement is AssignmentStatement) {
            $this->resolveAssignment($statement);
        } elseif ($statement is PrintStatement) {
            $this->resolvePrint($statement);
        } else {
            throw new \Exception("resolveStatement(): undefined statement type.");
        }
    }

    private function resolveAssignment(AssignmentStatement $statement): void {

        $varName = $statement->variable->name;
        invariant(! Str\is_empty($varName), "resolveAssignment(): variable name can NOT be empty.");
        $this->globalVar[$varName] = $statement->string;
    }

    private function resolvePrint(PrintStatement $statement): void {
    
        $varName = $statement->variable->name;
        invariant(! Str\is_empty($varName), "resolvePrint(): variable name can NOT be empty.");
        if (! isset($this->globalVar[$varName])) {
            throw new \Exception(
                Str\format("resolvePrint(): variable '$%s'not found.", $varName)
            );
        }
        $out = IO\request_output();
        $out->write($this->globalVar[$varName]);
    }
}
