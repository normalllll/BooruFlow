"""Read public JSON media fields only; never fetch artwork or use credentials."""
import concurrent.futures
import datetime
import json
from pathlib import Path
import urllib.request

SOURCES = {
    'danbooru': 'https://danbooru.donmai.us/posts/12408475.json',
    'aibooru': 'https://aibooru.online/posts.json?limit=1&tags=rating%3Ageneral',
    'gelbooru': 'https://gelbooru.com/index.php?page=dapi&s=post&q=index&json=1&limit=1&tags=rating%3Ageneral',
    'yande': 'https://yande.re/post.json?limit=1&tags=rating%3Asafe',
    'konachan_net': 'https://konachan.net/post.json?limit=1&tags=rating%3Asafe',
    'konachan_com': 'https://konachan.com/post.json?limit=1&tags=rating%3Asafe',
    'wallhaven': 'https://wallhaven.cc/api/v1/search?purity=100&sorting=date_added&page=1',
    'anime_pictures': 'https://api.anime-pictures.net/api/v3/posts?page=0&lang=en&ldate=0',
    'anime_pictures_detail': 'https://api.anime-pictures.net/api/v3/posts/932399',
}
FIELDS = {'id','file_ext','ext','file_type','file_url','large_file_url',
          'preview_file_url','sample_url','jpeg_url','preview_url','path','thumbs',
          'width','height','image_width','image_height','file_size','size','md5',
          'sample_width','sample_height','jpeg_width','jpeg_height','file_size'}

def fetch(entry):
    source, url = entry
    result = {'source': source, 'url': url}
    try:
        request = urllib.request.Request(url, headers={'User-Agent': 'BooruFlow-media-audit/1.0', 'Accept': 'application/json'})
        with urllib.request.urlopen(request, timeout=20) as response:
            result['http_status'] = response.status
            data = json.loads(response.read(1024 * 1024))
        if isinstance(data, dict):
            outer = data
            data = next((data[key] for key in ['post','posts','data'] if key in data), data)
            if isinstance(data, dict):
                data = {**data, **{k:v for k,v in outer.items() if k in FIELDS}}
        if isinstance(data, list): data = data[0] if data else {}
        result['media_fields'] = {k:v for k,v in data.items() if k in FIELDS}
        if not result['media_fields']: result['error'] = 'No post media fields returned'
    except Exception as error:
        result['error'] = str(error)
    return result

if __name__ == '__main__':
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(fetch, SOURCES.items()))
    output = {'observed_at': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'results': results}
    Path('build/r5-source-metadata.json').write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding='utf-8')
    for result in results:
        print(result['source'], result.get('http_status'), result.get('media_fields', {}).get('id'), result.get('error', 'OK'))
