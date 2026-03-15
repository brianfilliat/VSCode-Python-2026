function Subtract-Numbers {
    param(
        [Parameter(Mandatory=$true)] [double] $a,
        [Parameter(Mandatory=$true)] [double] $b
    )
    return ($a - $b)
}
