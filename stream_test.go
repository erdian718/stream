package stream_test

import (
	"fmt"
	"testing"

	"ofunc/lua/util"
)

func TestMain(m *testing.M) {
	l := util.NewState()
	util.AddPath(`../`)
	if err := util.Test(l, "test"); err != nil {
		fmt.Println("error:", err)
	}
}
