import asyncio
import json
import os
import multiprocessing
import subprocess
import zipfile
from asyncio import StreamReader, StreamWriter
import time
from worlds.paper_mario.Locations import location_table, location_to_name_table

from CommonClient import CommonContext, server_loop, gui_enabled, \
    ClientCommandProcessor, logger, get_base_parser
import Utils
from Utils import async_start
from worlds import network_data_package

location_name_to_id = network_data_package["games"]["Paper Mario"]["location_name_to_id"]

class PaperMarioCommandProcessor(ClientCommandProcessor):
    def __init__(self, ctx):
        super().__init__(ctx)

    def _cmd_sendcoin(self):
        if isinstance(self.ctx, PaperMarioContext):
            if self.ctx.streams:
                self.ctx.streams[1].write("[{\"req\": \"coin\"}]\n".encode())


class PaperMarioContext(CommonContext):
    command_processor = PaperMarioCommandProcessor
    items_handling = 0b001

    def __init__(self, server_address, password):
        super().__init__(server_address, password)
        self.streams: (StreamReader, StreamWriter) = None
        self.bizhawk_sync_task = None
        self.location_table = {}
        self.game = 'Paper Mario'
    
    def run_gui(self):
        from kvui import GameManager

        class PaperMarioManager(GameManager):
            logging_pairs = [
                ("Client", "Archipelago")
            ]
            base_title = "Archipelago Paper Mario Client"

        self.ui = PaperMarioManager(self)
        self.ui_task = asyncio.create_task(self.ui.async_run(), name="UI")

async def parse_payload(payload: dict, ctx: PaperMarioContext):
    # logger.debug('got msg' + str(payload))
    
    if not ctx.auth:
        ctx.auth = 'danny'
        await ctx.send_connect()

    if 'locations' in payload:
        locations = payload['locations']
        if isinstance(locations, list):
            locations = {}

        if ctx.location_table != locations:
            ctx.location_table = locations
            to_post=[{
                'cmd': 'LocationChecks',
                'locations': [ location_name_to_id[location_to_name_table[loc]] for loc, collected in ctx.location_table.items() if collected and loc in location_to_name_table and location_to_name_table[loc] in location_name_to_id ]
            }]
            logger.debug('sending location table' + str(to_post))
            await ctx.send_msgs(to_post)

async def bizhawk_sync(ctx:PaperMarioContext):
    logger.info("Starting connector.")
    while not ctx.exit_event.is_set():
        error_status = None
        if ctx.streams:
            (reader, writer) = ctx.streams
            writer.write("[{\"req\": \"ping\"}]\n".encode())
            try:
                await asyncio.wait_for(writer.drain(), timeout=1.5)
                try:
                    data = await asyncio.wait_for(reader.readline(), timeout=10)
                    data_decoded = json.loads(data.decode())
                    for msg in data_decoded:
                        async_start(parse_payload(msg, ctx))
                except asyncio.TimeoutError:
                    logger.debug("Read Timed Out, Reconnecting")
                    # error_status = CONNECTION_TIMING_OUT_STATUS
                    writer.close()
                    ctx.streams = None
                except ConnectionResetError as e:
                    logger.debug("Read failed due to Connection Lost, Reconnecting")
                    # error_status = CONNECTION_RESET_STATUS
                    writer.close()
                    ctx.streams = None
            except asyncio.TimeoutError:
                logger.debug("Read Timed Out, Reconnecting")
                # error_status = CONNECTION_TIMING_OUT_STATUS
                writer.close()
                ctx.streams = None
            except ConnectionResetError as e:
                logger.debug("Read failed due to Connection Lost, Reconnecting")
                # error_status = CONNECTION_RESET_STATUS
                writer.close()
                ctx.streams = None
        else:
            try:
                logger.debug("Attempting to connect to Bizhawk")
                ctx.streams = await asyncio.wait_for(asyncio.open_connection("localhost", 43088), timeout=10)
                logger.debug("Established connection to Bizhawk")
            except TimeoutError:
                logger.debug("Connection timed out")
            except ConnectionRefusedError:
                logger.debug("Connection refused")

        await asyncio.sleep(1)

if __name__ == '__main__':
    Utils.init_logging('PaperMarioClient')

    async def main():
        multiprocessing.freeze_support()
        parser = get_base_parser()
        args = parser.parse_args()

        ctx = PaperMarioContext(args.connect, args.password)
        ctx.server_task = asyncio.create_task(server_loop(ctx), name="Server Loop")
        if gui_enabled:
            ctx.run_gui()
        ctx.run_cli()
        ctx.bizhawk_sync_task = asyncio.create_task(bizhawk_sync(ctx), name="Bizhawk Sync")
        await ctx.exit_event.wait()
        ctx.server_address = None

        await ctx.shutdown()

        if ctx.bizhawk_sync_task:
            await ctx.bizhawk_sync_task

    import colorama
    colorama.init()
    asyncio.run(main())
    colorama.deinit()