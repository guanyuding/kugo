package naming

import (
	"fmt"
	"runtime"
	"strings"
)

const (
	depth = 1000
)

//NS xx
type NS []Naming

//Naming The caller info
type Naming struct {
	FuncName string
	FileName string
	Line     int
	Bool     bool
}

func (n Naming) String() string {
	if n.Bool {
		return fmt.Sprintf("Func [%s], File [%s],Line [%d]\n", n.FuncName, n.FileName, n.Line)
	}
	return ""
}

func (ns NS) String() string {
	var names = make([]string, len(ns))
	for i, n := range ns {
		if n.Bool {
			names[i] = fmt.Sprintf("Func [%s], File [%s],Line [%d], step [%d];\n", n.FuncName, n.FileName, n.Line, len(ns)-i)
		}
	}
	return strings.TrimSpace(strings.Join(names, ""))
}

//MyName return current function or method name
func MyName() Naming {
	pc, file, line, b := runtime.Caller(1)
	return Naming{
		FuncName: runtime.FuncForPC(pc).Name(),
		FileName: file,
		Line:     line,
		Bool:     b,
	}
}

//CallerName return the caller's name for current function or method name
func CallerName() Naming {
	pc, file, line, b := runtime.Caller(2)
	return Naming{
		FuncName: runtime.FuncForPC(pc).Name(),
		FileName: file,
		Line:     line,
		Bool:     b,
	}
}

//Trace return the full stack caller's name
func Trace() NS {
	pc := make([]uintptr, depth) // at least 1 entry needed
	n := runtime.Callers(1, pc)
	frames := runtime.CallersFrames(pc[1:n])
	var (
		i          = 0
		frameSlice = make(NS, n-1)
	)
	for {
		frame, more := frames.Next()
		fmt.Printf("%s:%d %s\n", frame.File, frame.Line, frame.Function)
		frameSlice[i] = Naming{
			FuncName: frame.Func.Name(),
			FileName: frame.File,
			Line:     frame.Line,
			Bool:     true,
		}
		i++
		if !more {
			break
		}
	}
	return frameSlice
}
