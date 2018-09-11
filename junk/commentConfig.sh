declare -A defaults
declare -A types

type=0
types=(['bash']=0)

exts=('sh')
startReg=(":'")
endReg=("'")
nameReg=('([^\s]{5,})\s*?\(')
argReg=('\@([^-]*)\s*')
argDefSep=('-')
argDescReg=('\s*([^@^:]*)')
