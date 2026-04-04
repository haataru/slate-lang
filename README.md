# Slate

<div align="center">
  <img src="https://i.postimg.cc/hj9nKrNy/rounded-in-photoretrica.png" alt="Slate Logo" width="300" height="300">
</div>

<br>

<div align="right">
  <strong>Slate</strong> v0.1<br>
  <strong>Language</strong> Zig<br>
  <strong>Type</strong> Interpreted<br>
  <strong>Memory</strong> Stack<br>
  <strong>License</strong> MIT
</div>

Простой интерпретируемый язык программирования с ручным управлением памятью, написанный на Zig.

---

## Возможности

- Объявление переменных (`let`)
- Целочисленные литералы (i32)
- Функция `print` для вывода
- Функции с точкой входа `main`
- Блоки `{ ... }`
- Указатели (экспериментально: `&` и `*`)

## Синтаксис

```slate
fn main() {
    let x: i32 = 123
    print(x)
}
```

## Сборка

```bash
zig build
```

## Запуск

```bash
./zig-out/bin/slatec <input.sl>
```

## Пример

```slate
fn main() {
    let x = 42
    let ptr = &x
    
    print(x)   // 42
    print(*ptr) // 42
}
```

## Архитектура

```
src/
├── main.zig          # Точка входа
├── lexer/            # Лексический анализ
├── parser/           # Синтаксический анализ
├── ast/              # Определения AST
└── interpreter/      # Интерпретатор
```

### Этапы выполнения

1. **Лексер** — преобразует исходный код в токены
2. **Парсер** — строит AST из токенов
3. **Интерпретатор** — выполняет AST

Интерпретатор использует стековую модель памяти с таблицей символов.


