import logging
import os
import random
from copy import deepcopy
from typing import Dict, List

import yaml
from pmrseedgen.db.item import Item
from pmrseedgen.db.node import Node
from pmrseedgen.models.MarioInventory import MarioInventory
from pmrseedgen.models.options.OptionSet import OptionSet
from pmrseedgen.rando_modules.logic import find_available_nodes, _depth_first_search
from pmrseedgen.random_seed import RandomSeed
from pmrseedgen.randomizer import write_data_to_rom
from yaml import SafeLoader

import settings

from BaseClasses import Tutorial, Region, CollectionState, ItemClassification, MultiWorld, Entrance
from .Options import paper_mario_options

from ..AutoWorld import World, WebWorld
from ..generic.Rules import add_rule

logger = logging.getLogger("Paper Mario")

from .Items import PaperMarioItem, base_id, item_table
from .Locations import PaperMarioLocation, location_table, location_to_name_table

from pmrseedgen.worldgraph import get_all_edges, get_all_nodes, generate, enrich_graph_data
from .Edges import edges


# class PaperMarioCollectionState(metaclass=AutoLogicRegister)

class PaperMarioSettings(settings.Group):
    class RomFile(settings.UserFilePath):
        """File name of the Paper Mario ROM"""
        description = "Paper Mario ROM File"
        copy_to = "Paper Mario.z64"

    rom_file: RomFile = RomFile(RomFile.copy_to)

class PaperMarioWeb(WebWorld):
    tutorials = [Tutorial(
        "Multiworld Setup Tutorial",
        "A guide to setting up Archipelago Paper Mario",
        "English",
        "setup_en.md",
        "setup/en",
        ["okdanny_"]
    )]

class PaperMarioWorld(World):
    """
    test!!!
    """

    game: str = "Paper Mario"
    web = PaperMarioWeb()
    option_definitions = paper_mario_options
    item_name_to_id = {index: (base_id + item['id']) for index, item in item_table.items()}
    location_name_to_id = {index: (base_id + loc.id) for index, loc in location_table.items()}

    required_client_version = (0, 4, 3)

    def __init__(self, multiworld: MultiWorld, player: int):
        World.__init__(self, multiworld, player)
        self.reachability_count = 0
        self.reachability_checked = set()
        self.seed = None
        self.graph = None
        self.graph_base = None
        self.rando_settings = None

    def generate_early(self) -> None:
        with open("./worlds/paper_mario/default.yaml", "r", encoding="utf-8") as file:
            data = yaml.load(file, Loader=SafeLoader)
            rando_settings = OptionSet()
            rando_settings.update_options(data)

            self.seed = RandomSeed(rando_settings)
            self.graph_base = generate(None, None)
            self.seed.generate(self.graph_base)
            self.graph = enrich_graph_data(deepcopy(self.graph_base))
            self.rando_settings = rando_settings


    def pre_fill(self) -> None:
        assert self.seed is not None
        for item in self.seed.starting_items:
            print(f"Placing {item}")
            self.multiworld.push_precollected(self.create_item(item))
        for partner in self.seed.starting_partners:
            print(f"Placing {partner}")

            self.multiworld.push_precollected(self.create_item(partner))

        # todo: always_peekaboo?
        if self.rando_settings.always_ispy:
            self.multiworld.push_item(self.multiworld.get_location(location_to_name_table['MAC_01/GiftA'], self.player), self.create_item('ISpy'))

        if self.rando_settings.always_speedyspin:
            self.multiworld.push_item(self.multiworld.get_location(location_to_name_table['MAC_01/ShopBadgeA'], self.player), self.create_item('SpeedySpin'))

        # self.multiworld.get_location(location_to_name_table['KKJ_25/0'], self.player).place_locked_item(self.create_item('Victory'))

    def create_regions(self) -> None:
        nodes = self.seed.placed_items
        regions: Dict[str, Region] = {}
        self.multiworld.regions.append(Region('Menu', self.player, self.multiworld))
        any = False

        for edge in edges:
            if edge['from']['map'] not in regions:
                regions[edge['from']['map']] = Region(edge['from']['map'], self.player, self.multiworld)
                self.multiworld.regions.append(regions[edge['from']['map']])

            if edge['to']['map'] not in regions:
                regions[edge['to']['map']] = Region(edge['to']['map'], self.player, self.multiworld)
                self.multiworld.regions.append(regions[edge['to']['map']])

        for node in nodes + [self.graph_base['KKJ_25/0']['node']]:
            # todo: filter nodes that don't matter
            if node is None:
                continue

            any = True

            if node.map_area.name not in regions:
                regions[node.map_area.name] = Region(node.map_area.name, self.player, self.multiworld)
                self.multiworld.regions.append(regions[node.map_area.name])

            if node.identifier in location_to_name_table:
                location_name = location_to_name_table[node.identifier]
                regions[node.map_area.name].locations.append(
                    PaperMarioLocation(
                        self.player,
                        location_name,
                        self.location_name_to_id[location_name],
                        regions[node.map_area.name]
                    )
                )
            else:
                assert False

        assert any

    def construct_inventory(self, state: CollectionState, player: int) -> MarioInventory:
        items = state.prog_items[player]
        # todo: use options to default inventory
        inventory = MarioInventory()

        for item in items:
            for i in range(items[item]):
                inventory.add(item)

        return inventory

    def generate_node_accessibility(self, node: Node):
        checks = []
        mapkey = node.identifier.split('/')[0]
        node_id = node.identifier.split('/')[1]
        for search_node in self.graph_base:
            edges = self.graph_base[search_node]['edge_list']
            for edge in edges:
                if (edge['from']['map'] == mapkey) and (str(edge['from']['id']) == node_id):
                    edge_check = edge['to']
                elif (edge['to']['map'] == mapkey) and (str(edge['to']['id']) == node_id):
                    edge_check = edge['from']
                else:
                    continue

                # assert edge_check is not None

                edge_check_name = location_to_name_table[f"{edge_check['map']}/{edge_check['id']}"]
                # print(f"looking for {edge_check_name}")

                def check(state):
                    if self.reachability_count == 0:
                        self.reachability_checked = set()

                    if node.identifier == 'MAC_00/4':
                        return True

                    if node.identifier in self.reachability_checked:
                        return False

                    self.reachability_count += 1
                    inventory = self.construct_inventory(state, self.player)

                    ret = False
                    if inventory.requirements_fulfilled(edge['reqs']):
                        self.reachability_checked.add(node.identifier)
                        can_reach = self.is_node_reachable(f"{edge_check['map']}/{edge_check['id']}", 'MAC_00/4', inventory)
                        # available_nodes, mario = find_available_nodes(self.graph, 'MAC_00/4', inventory)
                        # # print(available_nodes)
                        # can_reach = False
                        # for available_node in available_nodes:
                        #     # print(f"comparing {edge_check_name} with {location_to_name_table[available_node.identifier]}")
                        #     if edge_check_name == location_to_name_table[available_node.identifier]:
                        #         # print(f"found match for {edge_check_name}!")
                        #         can_reach = True
                        #         break

                        ret = can_reach
                    self.reachability_count -= 1
                    #
                    # if ret:
                    #     print(f"{node.identifier} is reachable")
                    return ret

                checks.append(check)

        return lambda state: any(map(lambda x: x(state), checks))



    def set_rules(self):
        for node in self.seed.placed_items:
            identifier = node.identifier
            entry = self.graph_base[identifier]
            name = location_to_name_table[identifier]
            location = self.multiworld.get_location(name, self.player)
            add_rule(location, self.generate_node_accessibility(entry['node']))

        self.multiworld.completion_condition[self.player] = lambda state: state.can_reach(location_to_name_table['KKJ_25/0'], 'Location', self.player)

        self.create_edges()


    def create_item(self, name: str):
        item_id = self.item_name_to_id[name]
        item = item_table[name]

        if item['item_type'] == 'OTHER':
            classification = ItemClassification.progression
        elif item['item_type'] == 'KEYITEM':
            classification = ItemClassification.progression_skip_balancing
        elif item['item_type'] == 'BADGE':
            classification = ItemClassification.useful
        elif item['item_type'] == 'STARPIECE':
            classification = ItemClassification.useful
        elif item['item_type'] == 'POWERSTAR':
            classification = ItemClassification.filler
        elif item['item_type'] == 'GEAR':
            classification = ItemClassification.progression
        elif item['item_type'] == 'PARTNERUPGRADE':
            classification = ItemClassification.progression
        elif item['item_type'] == 'PARTNER':
            classification = ItemClassification.progression
        else:
            classification = ItemClassification.filler

        return PaperMarioItem(name, classification, item_id, self.player)

    def create_items(self):
        assert self.seed is not None

        for node in self.seed.placed_items:
            if node.identifier == 'KKJ_25/0':
                print("skipping bowser reward")
                continue
            item = node.current_item
            if item is not None:
                self.multiworld.itempool.append(self.create_item(item.item_name))

    def get_filler_item_name(self) -> str:
        filler_items = Item.select().where(Item.item_type == 'ITEM' or Item.item_type == 'COIN')
        return random.choice(filler_items).item_name

    def connect_regions(self, source: str, dest: str, reqs=None):
        source_region = self.multiworld.get_region(source, self.player)
        dest_region = self.multiworld.get_region(dest, self.player)
        entrance = Entrance(self.player, '', source_region)

        if reqs:
            entrance.access_rule = lambda state: self.construct_inventory(state, self.player).requirements_fulfilled(reqs)

        source_region.exits.append(entrance)
        entrance.connect(dest_region)

    def create_edges(self):
        self.connect_regions('Menu', 'MAC_00')
        for edge in edges:
            if edge['from']['map'] != edge['to']['map']:
                self.connect_regions(edge['from']['map'], edge['to']['map'], edge['reqs'])
                self.connect_regions(edge['to']['map'], edge['from']['map'], edge['reqs'])

    def is_node_reachable(self, node: str, starting_node_id: str, mario: MarioInventory) -> bool:
        reachable_node_ids = {starting_node_id}
        non_traversable_edges = dict()
        non_traversable_edges[starting_node_id] = [
            edge["edge_id"] for edge in self.graph[starting_node_id]["edge_list"]
        ]

        reachable_item_nodes = {}  # < hmmm
        filled_item_node_ids = set()
        checked_item_node_ids = set()  # set() of str()
        while True:
            found_new_items = False

            # Re-traverse already found edges which could not be traversed before.
            node_ids_to_check = set()  # set() of str()
            for from_node_id in non_traversable_edges:
                node_ids_to_check.add(from_node_id)

            # logging.debug("%s", node_ids_to_check)
            for from_node_id in node_ids_to_check:
                found_additional_items, mario = _depth_first_search(
                    from_node_id,
                    self.graph,
                    reachable_node_ids,
                    reachable_item_nodes,
                    non_traversable_edges,
                    mario
                )
                found_new_items = found_new_items or found_additional_items

            if node in reachable_node_ids:
                return True

            # Check if an item node is reachable which already has an item placed.
            for node_id in (reachable_item_nodes.keys() - checked_item_node_ids):
                item_node = reachable_item_nodes[node_id]
                current_item = item_node.current_item
                if current_item:
                    mario.add(current_item.item_name)
                    found_new_items = True
                    filled_item_node_ids.add(node_id)

                checked_item_node_ids.add(node_id)

            # Keep searching for new edges and nodes until we don't find any new
            # items which might open up even more edges and nodes
            if not found_new_items:
                break

        return False

    def generate_output(self, output_directory: str) -> None:
        for location in self.multiworld.get_filled_locations(self.player):
            rando_id = location_table[location.name].identifier


            for node in self.seed.placed_items:
                if node.identifier == rando_id:
                    print(f'Putting {location.item.name} in {rando_id}')
                    node.current_item = Item.select().where(Item.item_name == location.item.name)
                    break

        write_data_to_rom(
            target_modfile='C:/Users/danie/Downloads/base_rando_0.24.2beta(1).z64',
            options=self.rando_settings,
            placed_items=self.seed.placed_items,
            placed_blocks=self.seed.placed_blocks,
            entrance_list=self.seed.entrance_list,
            enemy_stats=self.seed.enemy_stats,
            battle_formations=self.seed.battle_formations,
            move_costs=self.seed.move_costs,
            itemhints=self.seed.itemhints,
            coin_palette_data=self.seed.coin_palette.data,
            coin_palette_targets=self.seed.coin_palette.targets,
            coin_palette_crcs=self.seed.coin_palette.crcs,
            palette_data=self.seed.palette_data,
            quiz_data=self.seed.quiz_list,
            music_list=self.seed.music_list,
            seed_id=self.seed.seed_hash
        )