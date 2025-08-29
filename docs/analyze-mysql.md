# analyze

```mysql
EXPLAIN ANALYZE SELECT * FROM users;
-- -> Table scan on users  (cost=1.05 rows=8) (actual time=0.692..0.738 rows=8 loops=1)
```
