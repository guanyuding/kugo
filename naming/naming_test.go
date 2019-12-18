package naming

import (
	"testing"
)

func TestMyName(t *testing.T) {
	t.Logf("My name is [%s]!\n", MyName().String())
}

func TestCallerName(t *testing.T) {
	t.Logf("My caller is [%s]!\n", CallerName().String())
}

func TestTrace(t *testing.T) {
	frames := Trace().String()
	t.Log(frames)
	// for _, frame := range frames {
	// 	t.Logf("%s:%d %s\n", frame.FileName, frame.Line, frame.FuncName)
	// }
}
