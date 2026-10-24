```text
>- YAML ka folded block scalar hai. Yeh multiple YAML lines ko mila kar ek single-line string banata hai aur aakhir ka newline remove kar deta hai.
```
Symbols ka matlab:
Symbol	Kaam
```text
>	Multiple lines ko ek line mein jor deta hai
-	String ke end ka newline remove karta hai
>-	Lines ko jorna + ending newline remove karna
```

Comparison:
# Folded: output ek line mein
```text
msg: >-
  Hello
  Khalid
```
Output:
```text
Hello Khalid
```
# Literal: line breaks preserve hongi
```text
msg: |-
  Hello
  Khalid
```
Output:
```text
Hello
Khalid
```


