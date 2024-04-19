package main

import (
	"bufio"
	"fmt"
	"os"

	envp "github.com/hashicorp/go-envparse"
)

func main() {
	args := os.Args[1:]

	if len(args) < 2 {
		fmt.Println("Not enough arguments")
		os.Exit(1)
	}

	templatepath := args[0]
	envfilepath := args[1]

	envfile, err := os.Open(envfilepath)
	if err != nil {
		fmt.Println("Couldn't open env file")
		os.Exit(1)
	}

	envvalues, err := envp.Parse(envfile)
	if err != nil {
		fmt.Println("Malformed env file")
		os.Exit(1)
	}

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
					val, ok := envvalues[varfound]
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
