package main

import "time"

type Color int32

type CardDetails struct {
	Id             string
	Text           string
	TitleColor     Color
	Type           string
	Password       *string
	Red            int
	Green          int
	Blue           int
	Tags           []string
	Note           *string
	ImageFront     []byte
	ImageBack      []byte
	LastModifiedAt time.Time
}

type CardSummary struct {
	Id             string
	Text           string
	Type           string
	Password       *string
	LastModifiedAt time.Time
}
