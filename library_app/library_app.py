#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Учёт книг в библиотеке — приложение для пунктов 9–10 задания.

Только стандартная библиотека Python 3.10+ (никаких pip install):
  tkinter           — окна
  socket/hashlib/hmac — собственный мини-клиент PostgreSQL (в стандартной
                        библиотеке драйвера PostgreSQL нет)
  zipfile           — отчёт в формате Excel (.xlsx)

Запуск:               python library_app.py
Назначить роль:       python library_app.py --set-role ЛОГИН admin|manager|user

Приложение само читает структуру БД (таблицы, поля, ключи, домены),
поэтому формы и выпадающие списки строятся автоматически.
"""
import base64
import datetime
import hashlib
import hmac
import os
import re
import socket
import struct
import sys
import zipfile
from xml.sax.saxutils import escape

# ───────────────────────── настройки ─────────────────────────
DEFAULTS = dict(
    host=os.getenv("PGHOST", "localhost"),
    port=os.getenv("PGPORT", "5432"),
    db=os.getenv("PGDATABASE", "Zagrebelniy"),
    user=os.getenv("PGUSER", "admin"),
    password=os.getenv("PGPASSWORD", ""),
)

TITLES = {"books": "Книги", "authors": "Авторы", "genres": "Жанры",
          "publishers": "Издательства", "loans": "Выдачи (заказы)",
          "loan_statuses": "Статусы заказов", "roles": "Роли",
          "users": "Пользователи"}
ROLE_RU = {"admin": "Администратор", "manager": "Менеджер", "user": "Пользователь"}

# Разделение функционала по ролям (None = всё). Это и есть «защита по ролям».
READ = {"admin": None,
        "manager": {"books", "authors", "genres", "publishers", "loans", "loan_statuses"},
        "user": {"books", "authors", "genres", "publishers", "loans"}}
WRITE = {"admin": None,
         "manager": {"books", "authors", "genres", "publishers"},
         "user": set()}

# Слова, по которым находим статусы заказа в таблице loan_statuses
KW_NEW = ("оформ", "нов", "new", "созд", "ожида", "pending", "ordered")
KW_ACC = ("принят", "accept", "подтвержд", "одобр", "approved", "готов")
KW_REC = ("получ", "выдан", "receiv", "issued")


# ───────────────── мини-клиент PostgreSQL (протокол v3) ─────────────────
class DBError(Exception):
    def __init__(self, fields):
        self.f = fields
        self.code = fields.get("C", "")
        super().__init__(fields.get("M", "Ошибка базы данных"))


class PG:
    """Подключение к PostgreSQL. Запросы с параметрами идут через
    «расширенный протокол» (Parse/Bind), значения НЕ подставляются в текст SQL —
    это основная защита от SQL-инъекций."""

    def __init__(self, host, port, db, user, password):
        self.user, self.password = user, password
        self.s = socket.create_connection((host, int(port)), timeout=10)
        self.s.settimeout(30)
        params = b"".join(k.encode() + b"\0" + v.encode() + b"\0" for k, v in
                          (("user", user), ("database", db), ("client_encoding", "UTF8"))) + b"\0"
        body = struct.pack("!i", 196608) + params
        self.s.sendall(struct.pack("!i", len(body) + 4) + body)
        self._auth()

    # --- низкий уровень ---
    def _recv(self, n):
        buf = b""
        while len(buf) < n:
            chunk = self.s.recv(n - len(buf))
            if not chunk:
                raise ConnectionError("Соединение с базой данных закрыто")
            buf += chunk
        return buf

    def _msg(self):
        t = self._recv(1)
        (ln,) = struct.unpack("!i", self._recv(4))
        return t, self._recv(ln - 4)

    @staticmethod
    def _pack(t, body=b""):
        return t + struct.pack("!i", len(body) + 4) + body

    def _send(self, t, body=b""):
        self.s.sendall(self._pack(t, body))

    @staticmethod
    def _fields(b):
        d = {}
        for part in b.split(b"\0"):
            if part:
                d[chr(part[0])] = part[1:].decode(errors="replace")
        return d

    # --- аутентификация (cleartext / md5 / SCRAM-SHA-256) ---
    def _auth(self):
        while True:
            t, b = self._msg()
            if t == b"R":
                (code,) = struct.unpack("!i", b[:4])
                if code == 0:
                    continue
                if code == 3:
                    self._send(b"p", self.password.encode() + b"\0")
                elif code == 5:
                    inner = hashlib.md5(self.password.encode() + self.user.encode()).hexdigest()
                    outer = hashlib.md5(inner.encode() + b[4:8]).hexdigest()
                    self._send(b"p", b"md5" + outer.encode() + b"\0")
                elif code == 10:
                    self._scram_start()
                elif code == 11:
                    self._scram_continue(b[4:].decode())
                elif code == 12:
                    self._scram_final(b[4:].decode())
                else:
                    raise DBError({"M": f"Неподдерживаемый способ входа в БД (код {code})"})
            elif t == b"E":
                raise DBError(self._fields(b))
            elif t == b"Z":
                return

    def _scram_start(self):
        self.cnonce = base64.b64encode(os.urandom(18)).decode()
        self.cfb = "n=,r=" + self.cnonce
        first = ("n,," + self.cfb).encode()
        self._send(b"p", b"SCRAM-SHA-256\0" + struct.pack("!i", len(first)) + first)

    def _scram_continue(self, sfirst):
        kv = dict(x.split("=", 1) for x in sfirst.split(","))
        salted = hashlib.pbkdf2_hmac("sha256", self.password.encode(),
                                     base64.b64decode(kv["s"]), int(kv["i"]))
        ckey = hmac.new(salted, b"Client Key", "sha256").digest()
        nofp = "c=biws,r=" + kv["r"]
        auth = (self.cfb + "," + sfirst + "," + nofp).encode()
        sig = hmac.new(hashlib.sha256(ckey).digest(), auth, "sha256").digest()
        proof = base64.b64encode(bytes(a ^ b for a, b in zip(ckey, sig))).decode()
        skey = hmac.new(salted, b"Server Key", "sha256").digest()
        self.server_sig = hmac.new(skey, auth, "sha256").digest()
        self._send(b"p", (nofp + ",p=" + proof).encode())

    def _scram_final(self, data):
        got = base64.b64decode(data.split("v=", 1)[1])
        if not hmac.compare_digest(got, self.server_sig):
            raise DBError({"M": "Сервер БД не прошёл проверку подлинности"})

    # --- запросы ---
    def run(self, sql, params=()):
        """Возвращает (колонки, строки, тег). Все значения — строки или None."""
        enc = [None if p is None else str(p).encode() for p in params]
        bind = (b"\0\0" + struct.pack("!h", 0) + struct.pack("!h", len(enc)) +
                b"".join(struct.pack("!i", -1) if p is None else struct.pack("!i", len(p)) + p for p in enc) +
                struct.pack("!h", 0))
        self.s.sendall(
            self._pack(b"P", b"\0" + sql.encode() + b"\0" + struct.pack("!h", 0)) +
            self._pack(b"B", bind) +
            self._pack(b"D", b"P\0") +
            self._pack(b"E", b"\0" + struct.pack("!i", 0)) +
            self._pack(b"S"))
        cols, rows, tag, err = [], [], "", None
        while True:
            t, b = self._msg()
            if t == b"T":
                (n,) = struct.unpack("!h", b[:2])
                pos, cols = 2, []
                for _ in range(n):
                    end = b.index(b"\0", pos)
                    cols.append(b[pos:end].decode())
                    pos = end + 1 + 18
            elif t == b"D":
                (n,) = struct.unpack("!h", b[:2])
                pos, row = 2, []
                for _ in range(n):
                    (ln,) = struct.unpack("!i", b[pos:pos + 4])
                    pos += 4
                    if ln == -1:
                        row.append(None)
                    else:
                        row.append(b[pos:pos + ln].decode())
                        pos += ln
                rows.append(tuple(row))
            elif t == b"C":
                tag = b[:-1].decode()
            elif t == b"E":
                err = self._fields(b)
            elif t == b"Z":
                break
        if err:
            raise DBError(err)
        return cols, rows, tag

    def rows(self, sql, params=()):
        return self.run(sql, params)[1]

    def count(self, sql, params=()):
        tag = self.run(sql, params)[2]
        try:
            return int(tag.split()[-1])
        except (ValueError, IndexError):
            return 0

    def close(self):
        try:
            self._send(b"X")
            self.s.close()
        except OSError:
            pass


def human(e):
    """Понятное сообщение об ошибке вместо технического."""
    if isinstance(e, DBError):
        f, msg = e.f, e.f.get("M", "")
        code, col = e.code, f.get("c", "")
        if code == "23502":
            return f"Поле «{col or '?'}» обязательно для заполнения."
        if code == "23503":
            if msg.startswith("update or delete"):
                return "Нельзя удалить или изменить запись: на неё ссылаются другие данные (например, выдачи)."
            return "Указана несуществующая связанная запись. Выберите значение из списка."
        if code == "23505":
            return "Такое значение уже есть в базе, а оно должно быть уникальным. " + f.get("D", "")
        if code == "23514":
            m = re.search(r"domain (\S+)", msg)
            dom = f.get("d") or (m.group(1) if m else "")
            if dom:
                return f"Значение не подходит под домен «{dom}». Проверьте формат."
            return f"Значение не прошло проверку ({f.get('n', 'ограничение')})."
        if code == "22001":
            return "Слишком длинное значение для этого поля."
        if code in ("22P02", "22007", "22008"):
            return "Неверный формат значения (буквы вместо числа или неверная дата; дата вида 2026-10-30)."
        if code == "22003":
            return "Число вне допустимого диапазона."
        if code in ("28P01", "28000"):
            return "Неверный логин или пароль для подключения к базе данных."
        if code == "3D000":
            return "База данных с таким именем не найдена."
        if code == "42501":
            return "Недостаточно прав в базе данных для этого действия."
        return "Ошибка базы данных: " + msg
    if isinstance(e, (ConnectionError, OSError)):
        return ("Нет связи с базой данных. Проверьте, что контейнер Docker запущен, "
                "и что хост и порт указаны верно.")
    return str(e)


def q(name):
    """Экранирование имени таблицы/поля (имена берутся только из схемы БД)."""
    return '"' + name.replace('"', '""') + '"'


# ───────────────────── структура БД ─────────────────────
SQL_TABLES = ("SELECT table_name FROM information_schema.tables "
              "WHERE table_schema='public' AND table_type='BASE TABLE' ORDER BY 1")
SQL_COLS = ("SELECT column_name, data_type, is_nullable, column_default, "
            "character_maximum_length, domain_name, is_identity "
            "FROM information_schema.columns WHERE table_schema='public' AND table_name=$1 "
            "ORDER BY ordinal_position")
SQL_PK = ("SELECT a.attname FROM pg_index i JOIN pg_class c ON c.oid=i.indrelid "
          "JOIN pg_namespace n ON n.oid=c.relnamespace "
          "JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum=ANY(i.indkey) "
          "WHERE i.indisprimary AND n.nspname='public' AND c.relname=$1")
SQL_FK = ("SELECT a.attname, cf.relname, af.attname FROM pg_constraint c "
          "JOIN pg_class ct ON ct.oid=c.conrelid JOIN pg_namespace n ON n.oid=ct.relnamespace "
          "JOIN pg_class cf ON cf.oid=c.confrelid "
          "JOIN pg_attribute a ON a.attrelid=c.conrelid AND a.attnum=c.conkey[1] "
          "JOIN pg_attribute af ON af.attrelid=c.confrelid AND af.attnum=c.confkey[1] "
          "WHERE c.contype='f' AND n.nspname='public' AND ct.relname=$1")


class Meta:
    def __init__(self, db):
        self.db = db
        self.t = {}
        self._opts = {}
        for (name,) in db.rows(SQL_TABLES):
            cols = [dict(name=r[0], type=r[1], null=r[2] == "YES", default=r[3],
                         maxlen=int(r[4]) if r[4] else None, domain=r[5], identity=r[6] == "YES")
                    for r in db.rows(SQL_COLS, (name,))]
            pk = [r[0] for r in db.rows(SQL_PK, (name,))]
            fks = {r[0]: (r[1], r[2]) for r in db.rows(SQL_FK, (name,))}
            self.t[name] = dict(cols=cols, pk=pk[0] if pk else None, fks=fks)

    def names(self, table):
        return [c["name"] for c in self.t[table]["cols"]]

    def label_col(self, table):
        m = self.t[table]
        names = self.names(table)
        for k in ("name", "title", "full_name", "fio", "login", "email", "username"):
            if k in names:
                return k
        for n in names:
            if any(k in n for k in ("name", "title")):
                return n
        for c in m["cols"]:
            if c["name"] != m["pk"] and c["type"] in ("character varying", "text", "character"):
                return c["name"]
        return m["pk"] or names[0]

    def options(self, table, col):
        """[(значение, подпись)] для выпадающего списка по внешнему ключу."""
        key = (table, col)
        if key not in self._opts:
            lc = self.label_col(table)
            rows = self.db.rows(f"SELECT {q(col)}, {q(lc)} FROM {q(table)} ORDER BY 2, 1")
            self._opts[key] = [(v, l if l is not None else v) for v, l in rows]
        return self._opts[key]

    def clear_cache(self):
        self._opts.clear()


# ───────────────────── бизнес-логика (без окон) ─────────────────────
def auto(c):
    return c["default"] is not None or c["identity"]


def role_key(name):
    n = (name or "").lower()
    if "admin" in n or "админ" in n:
        return "admin"
    if "manag" in n or "менедж" in n:
        return "manager"
    return "user"


def sha(text):
    return hashlib.sha256(text.encode()).hexdigest()


def md5(text):
    return hashlib.md5(text.encode(), usedforsecurity=False).hexdigest()


def check_pw(stored, password):
    """Пароль в БД может быть: sha256 (64 символа), md5 (32 символа) или обычным текстом."""
    if re.fullmatch(r"[0-9a-f]{64}", stored):
        expect = sha(password)
    elif re.fullmatch(r"[0-9a-f]{32}", stored):
        expect = md5(password)
    else:
        expect = password
    return hmac.compare_digest(stored.encode(), expect.encode())


class Core:
    def __init__(self, db):
        self.db = db
        self.meta = Meta(db)
        self._flow = None
        self._detect_users()

    # --- пользователи и роли ---
    def _detect_users(self):
        if "users" not in self.meta.t:
            raise RuntimeError("В базе данных нет таблицы users.")
        m = self.meta.t["users"]
        names = self.meta.names("users")
        self.pk = m["pk"]
        self.login_col = next((c for c in ("login", "username", "user_name", "email", "nickname")
                               if c in names), None)
        self.pw_col = next((c for c in names if "pass" in c.lower() or "pwd" in c.lower()), None)
        self.role_col = next((c for c, (t, _) in m["fks"].items() if t == "roles"),
                             "role_id" if "role_id" in names else None)
        if not (self.pk and self.login_col and self.pw_col):
            raise RuntimeError("В таблице users не найдены поля id, логина и пароля. "
                               "Поля таблицы: " + ", ".join(names))
        # каким способом хранятся пароли у уже существующих пользователей
        vals = [r[0] for r in self.db.rows(
            f"SELECT {q(self.pw_col)} FROM users WHERE {q(self.pw_col)} IS NOT NULL LIMIT 20")]
        n32 = sum(bool(re.fullmatch(r"[0-9a-f]{32}", v)) for v in vals)
        self.hash_kind = "md5" if vals and n32 * 2 >= len(vals) else "sha256"

    def roles(self):
        if "roles" not in self.meta.t:
            return []
        rpk = self.meta.t["roles"]["pk"]
        lc = self.meta.label_col("roles")
        return [(i, n, role_key(n)) for i, n in
                self.db.rows(f"SELECT {q(rpk)}, {q(lc)} FROM roles ORDER BY 1")]

    def role_id(self, key):
        return next((i for i, _, k in self.roles() if k == key), None)

    def login(self, login, password):
        cols = [self.pk, self.pw_col] + ([self.role_col] if self.role_col else [])
        rows = self.db.rows(f"SELECT {', '.join(q(c) for c in cols)} FROM users "
                            f"WHERE {q(self.login_col)} = $1", (login,))
        if not rows:
            return None
        row = rows[0]
        stored = row[1] or ""
        if not check_pw(stored, password):
            return None
        key = "user"
        if self.role_col and row[2] is not None:
            key = next((k for i, _, k in self.roles() if i == row[2]), "user")
        return dict(id=row[0], login=login, role=key)

    def new_user_role(self):
        """Первый зарегистрированный пользователь, если админа ещё нет, становится админом."""
        if self.role_col:
            admin = self.role_id("admin")
            if admin is not None and self.db.rows(
                    f"SELECT 1 FROM users WHERE {q(self.role_col)} = $1 LIMIT 1", (admin,)) == []:
                return admin
            uid = self.role_id("user")
            if uid is None:
                raise RuntimeError("В таблице roles нет роли обычного пользователя.")
            return uid
        return None

    def set_role(self, login, key):
        rid = self.role_id(key)
        if rid is None or not self.role_col:
            raise RuntimeError(f"Роль «{key}» не найдена в таблице roles.")
        return self.db.count(f"UPDATE users SET {q(self.role_col)} = $1 WHERE {q(self.login_col)} = $2",
                             (rid, login))

    def store_pw(self, value, col):
        if re.fullmatch(r"[0-9a-f]{32}|[0-9a-f]{64}", value):
            return value  # уже хэш (поле не меняли)
        ml = col["maxlen"]
        if self.hash_kind == "md5" and (ml is None or ml >= 32):
            return md5(value)  # так же, как у остальных пользователей в базе
        if ml is not None and ml < 64:
            return value
        return sha(value)

    # --- работа с данными ---
    def _check(self, table, names):
        known = self.meta.names(table)
        for n in names:  # белый список: в SQL попадают только настоящие имена полей
            if n not in known:
                raise ValueError(f"Неизвестное поле: {n}")

    def select(self, table, where=None):
        cols = self.meta.names(table)
        sql = f"SELECT {', '.join(q(c) for c in cols)} FROM {q(table)}"
        params = ()
        if where:
            self._check(table, [where[0]])
            sql += f" WHERE {q(where[0])} = $1"
            params = (where[1],)
        pk = self.meta.t[table]["pk"]
        if pk:
            sql += f" ORDER BY {q(pk)}"
        return cols, self.db.rows(sql, params)

    def insert(self, table, values):
        names = list(values)
        self._check(table, names)
        if names:
            ph = ", ".join(f"${i + 1}" for i in range(len(names)))
            sql = f"INSERT INTO {q(table)} ({', '.join(q(n) for n in names)}) VALUES ({ph})"
        else:
            sql = f"INSERT INTO {q(table)} DEFAULT VALUES"
        self.db.run(sql, [values[n] for n in names])
        self.meta.clear_cache()

    def update(self, table, pk_value, values):
        pk = self.meta.t[table]["pk"]
        names = list(values)
        self._check(table, names)
        sets = ", ".join(f"{q(n)} = ${i + 1}" for i, n in enumerate(names))
        self.db.run(f"UPDATE {q(table)} SET {sets} WHERE {q(pk)} = ${len(names) + 1}",
                    [values[n] for n in names] + [pk_value])
        self.meta.clear_cache()

    def delete(self, table, pk_value):
        pk = self.meta.t[table]["pk"]
        self.db.run(f"DELETE FROM {q(table)} WHERE {q(pk)} = $1", (pk_value,))
        self.meta.clear_cache()

    # --- связанный процесс: заказ → принять → (админ правит) → получить ---
    def flow(self):
        if self._flow:
            return self._flow
        L = self.meta.t.get("loans")
        if not L:
            raise RuntimeError("В базе нет таблицы loans.")
        fks = L["fks"]
        book = [c for c, (t, _) in fks.items() if t == "books"]
        usr = [c for c, (t, _) in fks.items() if t == "users"]
        st = [c for c, (t, _) in fks.items() if t == "loan_statuses"]
        if not (book and usr and st and L["pk"]):
            raise RuntimeError("В таблице loans не найдены внешние ключи на books, users и loan_statuses.")
        staff = ("manag", "staff", "librar", "admin", "employee")
        user_col = next((c for c in usr if not any(k in c.lower() for k in staff)), usr[0])
        mgr_col = next((c for c in usr if c != user_col), None)
        opts = self.meta.options("loan_statuses", fks[st[0]][1])

        def pick(words, used):
            for v, label in opts:
                if v not in used and any(w in label.lower() for w in words):
                    return v
        acc = pick(KW_ACC, set())
        rec = pick(KW_REC, {acc})
        new = pick(KW_NEW, {acc, rec})
        rest = [v for v, _ in opts if v not in {new, acc, rec}]
        if new is None and rest:
            new = rest.pop(0)
        if acc is None and rest:
            acc = rest.pop(0)
        if rec is None and rest:
            rec = rest.pop(0)
        if None in (new, acc, rec):
            raise RuntimeError("В таблице loan_statuses нужно минимум 3 статуса: "
                               "оформлен, принят, получен.")
        self._flow = dict(pk=L["pk"], book=book[0], user=user_col, mgr=mgr_col, status=st[0],
                          NEW=new, ACC=acc, REC=rec)
        return self._flow

    def _loan(self, loan_id):
        f = self.flow()
        rows = self.db.rows(f"SELECT {q(f['status'])}, {q(f['user'])} FROM loans "
                            f"WHERE {q(f['pk'])} = $1", (loan_id,))
        if not rows:
            raise ValueError("Заказ не найден.")
        return rows[0]

    def new_loan(self, user_id, book_id):
        f, L = self.flow(), self.meta.t["loans"]
        vals = {f["book"]: book_id, f["user"]: user_id, f["status"]: f["NEW"]}
        today = datetime.date.today()
        for c in L["cols"]:
            n = c["name"]
            if n in vals or n == L["pk"] or auto(c):
                continue
            if c["type"] == "date" or c["type"].startswith("timestamp"):
                if not c["null"] or "order" in n.lower():
                    days = 14 if any(k in n.lower() for k in ("due", "return", "срок")) else 0
                    vals[n] = (today + datetime.timedelta(days=days)).isoformat()
            elif not c["null"]:
                raise RuntimeError(f"Обязательное поле «{n}» таблицы loans приложение не заполняет. "
                                   "Задайте ему значение по умолчанию (DEFAULT) в БД.")
        self.insert("loans", vals)

    def accept(self, loan_id, manager_id):
        f = self.flow()
        if self._loan(loan_id)[0] != f["NEW"]:
            raise ValueError("Принять можно только новый (оформленный) заказ.")
        vals = {f["status"]: f["ACC"]}
        if f["mgr"]:
            vals[f["mgr"]] = manager_id
        self.update("loans", loan_id, vals)

    def receive(self, loan_id, user_id):
        f = self.flow()
        status, owner = self._loan(loan_id)
        if owner != str(user_id):
            raise ValueError("Это не ваш заказ.")
        if status != f["ACC"]:
            raise ValueError("Получить можно только заказ, который принял менеджер.")
        vals = {f["status"]: f["REC"]}
        today = datetime.date.today().isoformat()
        for c in self.meta.t["loans"]["cols"]:
            n = c["name"].lower()
            if (c["type"] == "date" or c["type"].startswith("timestamp")) and \
                    any(k in n for k in ("issue", "receiv", "выдач")):
                vals[c["name"]] = today
        self.update("loans", loan_id, vals)


# ───────────────────── отчёт Excel (.xlsx без библиотек) ─────────────────────
def write_xlsx(path, header, rows):
    def ref(i):
        s, i = "", i + 1
        while i:
            i, r = divmod(i - 1, 26)
            s = chr(65 + r) + s
        return s

    def cell(r, c, v, style=0):
        v = re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", "", str(v))
        a = f'r="{ref(c)}{r}"' + (f' s="{style}"' if style else "")
        if re.fullmatch(r"-?(0|[1-9]\d*)(\.\d+)?", v):
            return f"<c {a}><v>{v}</v></c>"
        return f'<c {a} t="inlineStr"><is><t xml:space="preserve">{escape(v)}</t></is></c>'

    body = ["<row r=\"1\">" + "".join(cell(1, j, h, 1) for j, h in enumerate(header)) + "</row>"]
    for i, row in enumerate(rows, start=2):
        body.append(f'<row r="{i}">' + "".join(cell(i, j, v) for j, v in enumerate(row)) + "</row>")
    ns = 'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
    sheet = (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet {ns}>'
             f'<cols><col min="1" max="{max(len(header), 1)}" width="22" customWidth="1"/></cols>'
             f'<sheetData>{"".join(body)}</sheetData></worksheet>')
    styles = (f'<?xml version="1.0" encoding="UTF-8" standalone="yes"?><styleSheet {ns}>'
              '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
              '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
              '<fills count="2"><fill><patternFill patternType="none"/></fill>'
              '<fill><patternFill patternType="gray125"/></fill></fills>'
              '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
              '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
              '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
              '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>'
              '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
              '</styleSheet>')
    head = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    rel = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", head +
                   '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
                   '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
                   '<Default Extension="xml" ContentType="application/xml"/>'
                   '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
                   '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
                   '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
                   '</Types>')
        z.writestr("_rels/.rels", head +
                   '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                   f'<Relationship Id="rId1" Type="{rel}/officeDocument" Target="xl/workbook.xml"/></Relationships>')
        z.writestr("xl/workbook.xml", head + f'<workbook {ns} xmlns:r="{rel}"><sheets>'
                   '<sheet name="Отчёт" sheetId="1" r:id="rId1"/></sheets></workbook>')
        z.writestr("xl/_rels/workbook.xml.rels", head +
                   '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
                   f'<Relationship Id="rId1" Type="{rel}/worksheet" Target="worksheets/sheet1.xml"/>'
                   f'<Relationship Id="rId2" Type="{rel}/styles" Target="styles.xml"/></Relationships>')
        z.writestr("xl/worksheets/sheet1.xml", sheet)
        z.writestr("xl/styles.xml", styles)


# ───────────────────────── окна (tkinter) ─────────────────────────
def run_gui():
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk

    ERRORS = (DBError, RuntimeError, ValueError, OSError)

    class RowDialog(tk.Toplevel):
        """Форма добавления/изменения записи. Поля строятся по структуре таблицы."""

        def __init__(self, app, table, row=None, skip=(), forced=None, title="", on_ok=None):
            super().__init__(app)
            self.app, self.core, self.table = app, app.core, table
            self.row, self.forced, self.on_ok = row, forced or {}, on_ok
            self.title(title or ("Изменение записи" if row else "Новая запись"))
            self.resizable(False, False)
            self.transient(app)
            m = self.core.meta.t[table]
            self.m = m
            self.w = {}
            r = 0
            for c in m["cols"]:
                n = c["name"]
                if n in skip or n in self.forced or (row is None and auto(c)):
                    continue
                editing_pk = row is not None and n == m["pk"]
                required = (not c["null"]) and not editing_pk
                ttk.Label(self, text=n + (" *" if required else "")).grid(row=r, column=0, sticky="e", padx=8, pady=4)
                cur = None if row is None else row.get(n)
                if n in m["fks"]:
                    opts = self.core.meta.options(*m["fks"][n])
                    mapping = {f"{lab} (№{v})": v for v, lab in opts}
                    if c["null"]:
                        mapping = {"": None, **mapping}
                    w = ttk.Combobox(self, values=list(mapping), state="readonly", width=38)
                    back = {v: k for k, v in mapping.items()}
                    w.set(back.get(cur, ""))
                    self.w[n] = (w, mapping, c)
                elif c["type"] == "boolean":
                    mapping = {"да": "true", "нет": "false"}
                    if c["null"]:
                        mapping = {"": None, **mapping}
                    w = ttk.Combobox(self, values=list(mapping), state="readonly", width=38)
                    w.set({"t": "да", "f": "нет"}.get(cur, ""))
                    self.w[n] = (w, mapping, c)
                else:
                    is_pw = "pass" in n.lower() or "pwd" in n.lower()
                    w = ttk.Entry(self, width=40, show="*" if is_pw else "")
                    if cur is not None:
                        w.insert(0, cur)
                    self.w[n] = (w, None, c)
                w.grid(row=r, column=1, padx=8, pady=4)
                hint = c["domain"] or c["type"]
                if c["type"] == "date":
                    hint += " (ГГГГ-ММ-ДД)"
                if editing_pk:
                    hint = "Id изменять нельзя"
                    w.state(["disabled"])
                ttk.Label(self, text=hint, foreground="gray").grid(row=r, column=2, sticky="w", padx=4)
                r += 1
            ttk.Button(self, text="Сохранить", command=self.save).grid(row=r, column=1, pady=10, sticky="e")
            ttk.Button(self, text="Отмена", command=self.destroy).grid(row=r, column=2, pady=10, sticky="w")
            self.grab_set()

        def save(self):
            vals = dict(self.forced)
            for n, (w, mapping, c) in self.w.items():
                if n == self.m["pk"] and self.row is not None:
                    continue  # Id при изменении не трогаем
                raw = w.get().strip()
                if mapping is not None:
                    val = mapping.get(raw)
                else:
                    val = raw or None
                if val is None and not c["null"]:
                    messagebox.showerror("Ошибка", f"Поле «{n}» обязательно для заполнения.", parent=self)
                    return
                if val is None and self.row is None:
                    continue  # при добавлении пустое поле = значение по умолчанию / NULL
                if val is not None and mapping is None and ("pass" in n.lower() or "pwd" in n.lower()):
                    val = self.core.store_pw(val, c)
                vals[n] = val
            try:
                if self.row is None:
                    self.core.insert(self.table, vals)
                else:
                    self.core.update(self.table, self.row[self.m["pk"]], vals)
            except ERRORS as e:
                messagebox.showerror("Ошибка", human(e), parent=self)
                return
            self.destroy()
            if self.on_ok:
                self.on_ok()

    class TableView(ttk.Frame):
        def __init__(self, parent, app, table):
            super().__init__(parent)
            self.app, self.core, self.table, self.me = app, app.core, table, app.me
            self.m = self.core.meta.t[table]
            role = self.me["role"]
            self.can_write = WRITE[role] is None or table in WRITE[role]
            self.cols = self.core.meta.names(table)
            self.pk = self.m["pk"]

            # поиск / фильтры / сортировка
            bar = ttk.Frame(self)
            bar.pack(fill="x", pady=2)
            self.search = tk.StringVar()
            ttk.Label(bar, text="Поиск по всем полям:").grid(row=0, column=0, sticky="e")
            ttk.Entry(bar, textvariable=self.search, width=30).grid(row=0, column=1, padx=4, sticky="w")
            ttk.Button(bar, text="Сбросить всё", command=self.reset).grid(row=0, column=2, padx=8)
            self.filters, self.sorts = [], []
            for i in range(2):
                ttk.Label(bar, text=f"Фильтр {i + 1}:").grid(row=1 + i, column=0, sticky="e")
                col, val = tk.StringVar(), tk.StringVar()
                cb = ttk.Combobox(bar, textvariable=col, values=[""] + self.cols, state="readonly", width=18)
                cb.grid(row=1 + i, column=1, padx=4, pady=1, sticky="w")
                ttk.Entry(bar, textvariable=val, width=22).grid(row=1 + i, column=2, padx=4, sticky="w")
                self.filters.append((col, val))
                col.trace_add("write", self.refresh)
                val.trace_add("write", self.refresh)
                ttk.Label(bar, text=f"Сортировка {i + 1}:").grid(row=1 + i, column=3, sticky="e", padx=(12, 0))
                scol, desc = tk.StringVar(), tk.IntVar()
                ttk.Combobox(bar, textvariable=scol, values=[""] + self.cols, state="readonly",
                             width=18).grid(row=1 + i, column=4, padx=4, sticky="w")
                ttk.Checkbutton(bar, text="убывание", variable=desc).grid(row=1 + i, column=5, sticky="w")
                self.sorts.append((scol, desc))
                scol.trace_add("write", self.refresh)
                desc.trace_add("write", self.refresh)
            self.search.trace_add("write", self.refresh)

            # таблица
            box = ttk.Frame(self)
            box.pack(fill="both", expand=True, pady=4)
            ids = [f"c{j}" for j in range(len(self.cols))]
            self.tree = ttk.Treeview(box, columns=ids, show="headings", selectmode="browse")
            for j, n in enumerate(self.cols):
                self.tree.heading(ids[j], text=n, command=lambda n=n: self.head_click(n))
                self.tree.column(ids[j], width=60 if n == self.pk else 130, anchor="w")
            sy = ttk.Scrollbar(box, orient="vertical", command=self.tree.yview)
            sx = ttk.Scrollbar(box, orient="horizontal", command=self.tree.xview)
            self.tree.configure(yscrollcommand=sy.set, xscrollcommand=sx.set)
            self.tree.grid(row=0, column=0, sticky="nsew")
            sy.grid(row=0, column=1, sticky="ns")
            sx.grid(row=1, column=0, sticky="ew")
            box.rowconfigure(0, weight=1)
            box.columnconfigure(0, weight=1)

            # кнопки
            btns = ttk.Frame(self)
            btns.pack(fill="x")
            self.info = ttk.Label(btns, text="")
            self.info.pack(side="right")
            if self.can_write:
                ttk.Button(btns, text="Добавить", command=self.add).pack(side="left", padx=2)
                if self.pk:
                    ttk.Button(btns, text="Изменить", command=self.edit).pack(side="left", padx=2)
                    ttk.Button(btns, text="Удалить", command=self.remove).pack(side="left", padx=2)
            if table == "loans":
                if role == "user":
                    ttk.Button(btns, text="Оформить заказ", command=self.order).pack(side="left", padx=2)
                    ttk.Button(btns, text="Получить заказ", command=self.receive).pack(side="left", padx=2)
                if role == "manager":
                    ttk.Button(btns, text="Принять заказ", command=self.accept).pack(side="left", padx=2)
            ttk.Button(btns, text="Отчёт Excel", command=self.export).pack(side="left", padx=12)
            ttk.Button(btns, text="Обновить", command=self.reload).pack(side="left", padx=2)
            self.reload()

        # --- данные ---
        def reload(self):
            try:
                where = None
                if self.table == "loans" and self.me["role"] == "user":
                    where = (self.core.flow()["user"], self.me["id"])  # обычный пользователь видит только свои заказы
                _, self.raw = self.core.select(self.table, where)
                maps = {n: dict(self.core.meta.options(*self.m["fks"][n])) for n in self.cols if n in self.m["fks"]}
            except ERRORS as e:
                messagebox.showerror("Ошибка", human(e))
                self.raw, maps = [], {}
            kinds = {c["name"]: c["type"] for c in self.m["cols"]}
            self.disp = []
            for row in self.raw:
                out = []
                for n, v in zip(self.cols, row):
                    if v is None:
                        out.append("")
                    elif n in maps:
                        out.append(str(maps[n].get(v, v)))
                    elif kinds[n] == "boolean":
                        out.append("да" if v == "t" else "нет")
                    else:
                        out.append(v)
                self.disp.append(out)
            self.refresh()

        def refresh(self, *_):
            idx = list(range(len(self.disp)))
            term = self.search.get().strip().lower()
            if term:
                idx = [i for i in idx if any(term in c.lower() for c in self.disp[i])]
            for col, val in self.filters:
                v = val.get().strip().lower()
                if col.get() and v:
                    j = self.cols.index(col.get())
                    idx = [i for i in idx if v in self.disp[i][j].lower()]

            def key(s):
                try:
                    return (0, float(s), "")
                except ValueError:
                    return (1, 0.0, s.lower())
            for col, desc in reversed(self.sorts):  # сортировка по двум полям
                if col.get():
                    j = self.cols.index(col.get())
                    idx.sort(key=lambda i: key(self.disp[i][j]), reverse=bool(desc.get()))
            self.shown = idx
            self.tree.delete(*self.tree.get_children())
            for i in idx:
                self.tree.insert("", "end", iid=str(i), values=self.disp[i])
            self.info.config(text=f"Записей: {len(idx)} из {len(self.disp)}")

        def head_click(self, name):
            col, desc = self.sorts[0]
            if col.get() == name:
                desc.set(0 if desc.get() else 1)
            else:
                col.set(name)
                desc.set(0)

        def reset(self):
            self.search.set("")
            for col, val in self.filters:
                col.set("")
                val.set("")
            for col, desc in self.sorts:
                col.set("")
                desc.set(0)

        def selected(self):
            sel = self.tree.selection()
            if not sel:
                messagebox.showinfo("Выбор записи", "Сначала выберите запись в таблице.")
                return None
            return dict(zip(self.cols, self.raw[int(sel[0])]))

        # --- действия ---
        def add(self):
            RowDialog(self.app, self.table, on_ok=self.reload)

        def edit(self):
            row = self.selected()
            if row:
                RowDialog(self.app, self.table, row=row, on_ok=self.reload)

        def remove(self):
            row = self.selected()
            if row and messagebox.askyesno("Удаление", "Удалить выбранную запись?"):
                self.act(lambda: self.core.delete(self.table, row[self.pk]), None)

        def act(self, fn, done):
            try:
                fn()
            except ERRORS as e:
                messagebox.showerror("Ошибка", human(e))
                return
            if done:
                messagebox.showinfo("Готово", done)
            self.reload()

        def order(self):
            try:
                opts = self.core.meta.options("books", self.core.meta.t["books"]["pk"])
                self.core.flow()
            except ERRORS as e:
                messagebox.showerror("Ошибка", human(e))
                return
            win = tk.Toplevel(self.app)
            win.title("Оформить заказ")
            win.transient(self.app)
            ttk.Label(win, text="Выберите книгу:").grid(row=0, column=0, padx=8, pady=8)
            mapping = {f"{lab} (№{v})": v for v, lab in opts}
            cb = ttk.Combobox(win, values=list(mapping), state="readonly", width=45)
            cb.grid(row=0, column=1, padx=8)

            def go():
                if not cb.get():
                    messagebox.showerror("Ошибка", "Выберите книгу из списка.", parent=win)
                    return
                book = mapping[cb.get()]
                win.destroy()
                self.act(lambda: self.core.new_loan(self.me["id"], book), "Заказ оформлен.")
            ttk.Button(win, text="Оформить", command=go).grid(row=1, column=1, pady=8, sticky="e")
            win.grab_set()

        def accept(self):
            row = self.selected()
            if row:
                self.act(lambda: self.core.accept(row[self.pk], self.me["id"]), "Заказ принят.")

        def receive(self):
            row = self.selected()
            if row:
                self.act(lambda: self.core.receive(row[self.pk], self.me["id"]), "Заказ получен.")

        def export(self):
            path = filedialog.asksaveasfilename(defaultextension=".xlsx", initialfile=f"{self.table}_report.xlsx",
                                                filetypes=[("Excel", "*.xlsx")])
            if not path:
                return
            try:
                write_xlsx(path, self.cols, [self.disp[i] for i in self.shown])
            except OSError as e:
                messagebox.showerror("Ошибка", f"Не удалось сохранить файл: {e}")
                return
            messagebox.showinfo("Отчёт", f"Отчёт сохранён:\n{path}\n(в файл попали записи, видимые в таблице)")

    class App(tk.Tk):
        def __init__(self):
            super().__init__()
            self.title("Учёт книг в библиотеке")
            self.geometry("1180x680")
            self.minsize(980, 520)
            self.core = self.me = None
            self.show_connect()

        def clear(self):
            for w in self.winfo_children():
                w.destroy()

        # --- подключение ---
        def show_connect(self):
            self.clear()
            f = ttk.Frame(self, padding=30)
            f.place(relx=0.5, rely=0.4, anchor="center")
            ttk.Label(f, text="Подключение к базе данных", font=("", 14, "bold")).grid(columnspan=2, pady=10)
            self.cv = {}
            for i, (k, label) in enumerate((("host", "Хост"), ("port", "Порт"), ("db", "База данных"),
                                            ("user", "Пользователь"), ("password", "Пароль"))):
                ttk.Label(f, text=label).grid(row=i + 1, column=0, sticky="e", padx=6, pady=3)
                e = ttk.Entry(f, width=28, show="*" if k == "password" else "")
                e.insert(0, DEFAULTS[k])
                e.grid(row=i + 1, column=1, pady=3)
                self.cv[k] = e
            ttk.Button(f, text="Подключиться", command=self.do_connect).grid(columnspan=2, pady=12)
            self.bind("<Return>", lambda _: self.do_connect())

        def do_connect(self):
            v = {k: e.get().strip() if k != "password" else e.get() for k, e in self.cv.items()}
            try:
                self.core = Core(PG(v["host"], v["port"], v["db"], v["user"], v["password"]))
            except ERRORS as e:
                messagebox.showerror("Подключение", human(e))
                return
            self.show_login()

        # --- вход / регистрация ---
        def show_login(self):
            self.clear()
            f = ttk.Frame(self, padding=30)
            f.place(relx=0.5, rely=0.4, anchor="center")
            ttk.Label(f, text="Вход в систему", font=("", 14, "bold")).grid(columnspan=2, pady=10)
            ttk.Label(f, text="Логин").grid(row=1, column=0, sticky="e", padx=6, pady=4)
            ttk.Label(f, text="Пароль").grid(row=2, column=0, sticky="e", padx=6, pady=4)
            self.e_login, self.e_pw = ttk.Entry(f, width=28), ttk.Entry(f, width=28, show="*")
            self.e_login.grid(row=1, column=1)
            self.e_pw.grid(row=2, column=1)
            ttk.Button(f, text="Войти", command=self.do_login).grid(row=3, column=1, sticky="e", pady=10)
            ttk.Button(f, text="Регистрация", command=self.register).grid(row=3, column=0, pady=10)
            self.e_login.focus()
            self.bind("<Return>", lambda _: self.do_login())

        def do_login(self):
            login, pw = self.e_login.get().strip(), self.e_pw.get()
            if not login or not pw:
                messagebox.showerror("Вход", "Введите логин и пароль.")
                return
            try:
                me = self.core.login(login, pw)
            except ERRORS as e:
                messagebox.showerror("Вход", human(e))
                return
            if not me:
                messagebox.showerror("Вход", "Неверный логин или пароль.")
                return
            self.me = me
            self.show_main()

        def register(self):
            try:
                rid = self.core.new_user_role()
                forced = {self.core.role_col: rid} if self.core.role_col else {}
                RowDialog(self, "users", forced=forced, title="Регистрация",
                          on_ok=lambda: messagebox.showinfo("Регистрация", "Готово! Теперь войдите в систему."))
            except ERRORS as e:
                messagebox.showerror("Регистрация", human(e))

        # --- основное окно ---
        def show_main(self):
            self.clear()
            self.unbind("<Return>")
            role = self.me["role"]
            top = ttk.Frame(self, padding=6)
            top.pack(fill="x")
            ttk.Label(top, text=f"{self.me['login']} — {ROLE_RU[role]}", font=("", 11, "bold")).pack(side="left")
            ttk.Button(top, text="Выйти", command=self.logout).pack(side="right")
            body = ttk.Frame(self)
            body.pack(fill="both", expand=True, padx=6, pady=4)
            allowed = READ[role]
            order = [t for t in TITLES if t in self.core.meta.t]
            order += [t for t in self.core.meta.t if t not in TITLES]
            self.tables = [t for t in order if allowed is None or t in allowed]
            self.nav = tk.Listbox(body, width=22, exportselection=False, activestyle="none", font=("", 11))
            for t in self.tables:
                self.nav.insert("end", TITLES.get(t, t))
            self.nav.pack(side="left", fill="y", padx=(0, 6))
            self.nav.bind("<<ListboxSelect>>", self.on_nav)
            self.pane = ttk.Frame(body)
            self.pane.pack(side="left", fill="both", expand=True)
            if self.tables:
                self.nav.selection_set(0)
                self.on_nav()

        def on_nav(self, *_):
            sel = self.nav.curselection()
            if not sel:
                return
            for w in self.pane.winfo_children():
                w.destroy()
            TableView(self.pane, self, self.tables[sel[0]]).pack(fill="both", expand=True)

        def logout(self):
            self.me = None
            self.show_login()

    App().mainloop()


def cli_set_role(login, key):
    import getpass
    if key not in ROLE_RU:
        sys.exit("Роль должна быть: admin, manager или user")
    d = dict(DEFAULTS)
    d["user"] = input(f"Пользователь БД [{d['user']}]: ").strip() or d["user"]
    if not d["password"]:
        d["password"] = getpass.getpass(f"Пароль пользователя БД {d['user']}: ")
    try:
        core = Core(PG(d["host"], d["port"], d["db"], d["user"], d["password"]))
        n = core.set_role(login, key)
    except (DBError, RuntimeError, OSError) as e:
        sys.exit(human(e))
    print("Готово." if n else "Пользователь с таким логином не найден.")


if __name__ == "__main__":
    if "--set-role" in sys.argv:
        i = sys.argv.index("--set-role")
        if len(sys.argv) < i + 3:
            sys.exit("Использование: python library_app.py --set-role ЛОГИН admin|manager|user")
        cli_set_role(sys.argv[i + 1], sys.argv[i + 2])
    else:
        run_gui()
