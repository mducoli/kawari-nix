package main

import (
	"bufio"
	"crypto/sha256"
	"fmt"
	"io"
	"os"
)

func trySubst(placeholder string) (string, bool) {
	if len(placeholder) < 84 || placeholder[0:7] != "KAWARI:" || placeholder[len(placeholder)-12:] != ":PLACEHOLDER" {
		return "", false
	}

	path := placeholder[72 : len(placeholder)-12]
	hash := placeholder[7:71]

	calculatedhash := fmt.Sprintf("%x", sha256.Sum256([]byte("kawari+"+path)))

	if hash != calculatedhash {
		return "", false
	}

	secretfile, err := os.Open(path)
	if err != nil {
		return "", false
	}

	secret, err := io.ReadAll(secretfile)
	if err != nil {
		return "", false
	}

	return string(secret), true
}

func main() {
	args := os.Args[1:]

	if len(args) < 1 {
		fmt.Println("Not enough arguments")
		os.Exit(1)
	}

	templatepath := args[0]

	templatefile, err := os.Open(templatepath)
	if err != nil {
		fmt.Println("Couldn't open template file")
		os.Exit(1)
	}

	scanner := bufio.NewScanner(templatefile)
	scanner.Split(bufio.ScanBytes)

	res := ""

loop1:
	for scanner.Scan() {
		c := scanner.Text()
		varfound := ""

		if c == "@" {
			for scanner.Scan() {
				ch := scanner.Text()

				if ch == "@" {
					val, ok := trySubst(varfound)
					if ok {
						res += val
					} else {
						res += "@" + varfound
						varfound = ""
						continue
					}
					continue loop1
				}
				varfound += ch
			}

			res += "@" + varfound
			continue
		}

		res += c
	}

	fmt.Print(res)
}
