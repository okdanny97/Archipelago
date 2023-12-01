from BaseClasses import Item
from typing import TypedDict, Dict
from pmrseedgen.db.db import db
from .utils import dict_factory, base_id


class PaperMarioItem(Item):
    game: str = "Paper Mario"

class ItemDict(TypedDict):
    id: int
    item_type: str
    value: int
    item_name: str
    base_price: int
    progression: int
    unused: int
    unused_duplicates: int
    unplaceable: 0


cur = db.cursor()
cur.row_factory = dict_factory
res = cur.execute('select * from item')
res = res.fetchall()

item_table: Dict[str, ItemDict] = {
    'Victory': {
        'id': 99999,
        'item_type': 'VICTORY',
        'value': 99999,
        'item_name': 'Victory',
        'base_price': 0,
        'progression': 1,
        'unused': 0,
        'unused_duplicates': 0,
        'unplaceable': 1
    }
}
for item in res:
    item_table[item['item_name']] = item

cur.close()
