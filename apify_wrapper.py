from apify import Actor
import subprocess
import asyncio
import os

async def main():
    async with Actor() as actor:
        input_data = await actor.get_input() or {}
        query = input_data.get('query', 'restaurants New York')
        depth = input_data.get('depth', 1)
        email = input_data.get('extract_emails', True)
        max_results = input_data.get('max_results', 100)

        # Create queries file
        queries_path = '/tmp/queries.txt'
        with open(queries_path, 'w') as f:
            f.write(query)

        # CLI command
        cmd = [
            '/google-maps-scraper',
            '-input', queries_path,
            '-results', '/tmp/output.csv',
            '-depth', str(depth),
            '-c', '4',
            '-max', str(max_results),
            '-exit-on-inactivity', '10m'
        ]
        if email:
            cmd.append('-email')

        actor.log.info(f'Running: {" ".join(cmd)}')
        process = subprocess.run(cmd, capture_output=True, text=True, timeout=600)

        if process.returncode != 0:
            actor.log.error(process.stderr)
            await actor.push_data([{'error': process.stderr}])
            return

        # Parse CSV to JSON
        results = []
        if os.path.exists('/tmp/output.csv'):
            with open('/tmp/output.csv', 'r') as f:
                lines = f.readlines()
                if len(lines) > 1:
                    headers = lines[0].strip().split(',')
                    for line in lines[1:]:
                        row = dict(zip(headers, line.strip().split(',')))
                        results.append(row)

        await actor.push_data(results or [{'message': 'No results found'}])

if __name__ == '__main__':
    asyncio.run(main())
