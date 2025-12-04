from apify import Actor
import subprocess
import json
import os
from pathlib import Path

async def main():
    async with Actor() as actor:
        input_data = await actor.get_input() or {}
        query = input_data.get('query', 'tech startups USA')
        depth = input_data.get('depth', 1)
        email_extract = input_data.get('email', True)
        
        # Create input file
        queries_path = '/tmp/queries.txt'
        with open(queries_path, 'w') as f:
            f.write(query)
        
        # Run CLI
        cmd = [
            '/google-maps-scraper',
            '-input', queries_path,
            '-results', '/tmp/results.csv',
            '-depth', str(depth),
            '-c', '4'  # Concurrency
        ]
        if email_extract:
            cmd.append('-email')
        cmd.append('-exit-on-inactivity')
        cmd.append('5m')
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise ValueError(f"CLI error: {result.stderr}")
        
        # Parse CSV to JSON for dataset
        with open('/tmp/results.csv', 'r') as f:
            lines = f.readlines()
            leads = []
            for line in lines[1:]:  # Skip header
                fields = line.strip().split(',')
                leads.append({'company': fields[0], 'address': fields[1], 'phone': fields[2], 'email': fields[3], 'website': fields[4]})
        
        await actor.push_data(leads)

if __name__ == '__main__':
    import asyncio
    asyncio.run(main())
