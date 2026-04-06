# Slate

<div align="center">
  <img src="https://i.postimg.cc/hj9nKrNy/rounded-in-photoretrica.png" alt="Slate Logo" width="300" height="300">
</div>

<div align="center">
  <strong>Slate</strong> v0.1 &nbsp;|&nbsp;
  <strong>Language</strong> Zig &nbsp;|&nbsp;
  <strong>Type</strong> Interpreted &nbsp;|&nbsp;
  <strong>Memory</strong> Stack &nbsp;|&nbsp;
  <strong>License</strong> MIT
</div>

<br>

Простой интерпретируемый язык программирования, написанный на Zig.

---

## Возможности

- Объявление переменных (`let`)
- Целочисленные литералы (i32)
- Функция `print` для вывода
- Функции с точкой входа `main`

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
    let x: i32 = 123
    print(x)
}
```

## Структура

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
