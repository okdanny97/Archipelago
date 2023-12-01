base_id = 9783983

def dict_factory(cursor, row):
    d = {}
    for idx, col in enumerate(cursor.description):
        d[col[0]] = row[idx]
    return d

def generate_location_name(region_id: str, map_area_name: str, vanilla_item) -> str:
    return f"({location['identifier'][:3]}) {location['map_area_name']} {location['item_name']}"

