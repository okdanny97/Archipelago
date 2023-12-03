from pmrseedgen.db.node import Node

from BaseClasses import Location
from typing import TypedDict, Dict
from pmrseedgen.db.db import db
from .utils import dict_factory, base_id

class PaperMarioLocation(Location):
    game: str = "Paper Mario"


class LocationDict(TypedDict):
    id: int
    map_area_id: int
    entrance_id: int
    entrance_type: str
    entrance_name: str
    key_name_item: str
    key_name_price: str
    item_source_type: int
    vanilla_item_id: int
    current_item_id: int
    vanilla_price: int
    item_index: int
    price_index: int
    identifier: str
    item_name: str
    map_area_name: str


locations = Node.select().where(True)

#
# cur = db.cursor()
# cur.row_factory = dict_factory
# res = cur.execute('select node.*, item.item_name as item_name, maparea.verbose_name as map_area_name from node join item on node.vanilla_item_id=item.id join maparea on node.map_area_id=maparea.id')
# res = res.fetchall()

location_table: Dict[str, Node] = {}
location_to_name_table: Dict[str, str] = {}
for location in locations:
    name = f"({location.identifier[:3]}) {location.map_area.name if location.map_area is not None else ''} {location.vanilla_item.item_name if location.vanilla_item is not None else ''}"
    location_table[name] = location
    location_to_name_table[location.identifier] = name

# cur.close()
