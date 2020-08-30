{$WARN SYMBOL_PLATFORM OFF}                                                     { Disable warning "Symbol '..' is specific to a platform" }

{$IFNDEF DEBUG}
  {$WEAKLINKRTTI ON}
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$ENDIF}

{;$DEFINE DEBUGUS}
