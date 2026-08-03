# main.py
from fastapi import FastAPI, HTTPException, Query, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from yt_dlp import YoutubeDL
from typing import Optional
import os
import uuid
import asyncio
from pydantic import BaseModel
import re
import json

app = FastAPI()

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

def detect_platform(url: str) -> str:
    """Detect the platform from the URL"""
    url_lower = url.lower()
    if 'youtube.com' in url_lower or 'youtu.be' in url_lower:
        return 'youtube'
    elif 'instagram.com' in url_lower:
        return 'instagram'
    elif 'tiktok.com' in url_lower:
        return 'tiktok'
    elif 'twitter.com' in url_lower or 'x.com' in url_lower:
        return 'twitter'
    elif 'facebook.com' in url_lower or 'fb.com' in url_lower:
        return 'facebook'
    elif 'reddit.com' in url_lower:
        return 'reddit'
    else:
        return 'generic'

def get_ydl_opts_for_platform(platform: str) -> dict:
    """Get yt-dlp options tailored for the platform"""
    base_opts = {
        'quiet': False,
        'no_warnings': False,
        'http_headers': {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept-Language': 'en-US,en;q=0.9',
        },
        'socket_timeout': 60,
    }
    
    if platform == 'instagram':
        base_opts.update({
            'format': 'best',
            'quiet': False,
            'no_warnings': False,
            'socket_timeout': 120,
        })
        
        # Check for Instagram credentials file
        cookies_file = 'instagram_cookies.txt'
        if os.path.exists(cookies_file):
            base_opts['cookiefile'] = cookies_file
            
    elif platform == 'tiktok':
        base_opts.update({
            'format': 'best',
        })
    elif platform == 'twitter':
        base_opts.update({
            'format': 'best',
        })
    elif platform == 'facebook':
        base_opts.update({
            'format': 'best',
        })
    else:
        # YouTube and others
        base_opts.update({
            'format': 'best',
        })
    
    return base_opts

# Temporary storage for download progress
download_status = {}

class VideoRequest(BaseModel):
    url: str

class DownloadRequest(BaseModel):
    url: str
    format_id: str

class InstagramLoginRequest(BaseModel):
    username: str
    password: str

@app.post("/api/video-info")
async def get_video_info(request: VideoRequest):
    try:
        platform = detect_platform(request.url)
        ydl_opts = get_ydl_opts_for_platform(platform)
        ydl_opts.update({
            'quiet': True,
            'no_warnings': True,
            'skip_download': True,
            'format': 'best',
        })

        with YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(request.url, download=False)
            
            formats = []
            if 'formats' in info:
                for f in info['formats']:
                    if f.get('vcodec') != 'none' or f.get('acodec') != 'none':
                        formats.append({
                            'format_id': f.get('format_id', 'best'),
                            'quality': f.get('format_note', f.get('ext', 'unknown')),
                            'type': 'Video' if f.get('vcodec') != 'none' else 'Audio',
                            'size': f.get('filesize', 0)
                        })
            
            # For Instagram and other platforms without formats, use 'best' as default
            if not formats:
                formats = [{
                    'format_id': 'best',
                    'quality': 'best',
                    'type': 'Video',
                    'size': 0
                }]

            return JSONResponse({
                'title': info.get('title', 'Unknown'),
                'thumbnail': info.get('thumbnail', ''),
                'duration': info.get('duration_string', 'Unknown'),
                'platform': platform,
                'formats': formats
            })
    
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=400, detail=f"Error: {str(e)}")

@app.post("/api/download")
async def download_video(request: DownloadRequest):
    download_id = str(uuid.uuid4())
    temp_filename = f"temp_{download_id}.mp4"
    
    async def download_task():
        try:
            platform = detect_platform(request.url)
            ydl_opts = get_ydl_opts_for_platform(platform)
            
            # Always use 'best' for safety - don't trust the client's format_id
            ydl_opts.update({
                'format': 'best',
                'outtmpl': temp_filename,
                'progress_hooks': [progress_hook],
            })

            with YoutubeDL(ydl_opts) as ydl:
                download_status[download_id] = {'progress': 0, 'status': 'downloading'}
                ydl.download([request.url])
                
                download_status[download_id]['status'] = 'completed'
                
                # Wait for client to pick up the file. 
                # Increased to 10 minutes to prevent premature deletion during slow downloads.
                # The primary cleanup should happen in get_download_file via BackgroundTasks.
                await asyncio.sleep(600) 
                
                # Fallback cleanup for abandoned downloads
                if os.path.exists(temp_filename):
                    try:
                        os.remove(temp_filename)
                    except:
                        pass
                if download_id in download_status:
                    del download_status[download_id]

        except Exception as e:
            import traceback
            traceback.print_exc()
            download_status[download_id] = {'status': 'error', 'error': str(e)}

    def progress_hook(d):
        if d['status'] == 'downloading':
            if download_id in download_status:
                download_status[download_id]['progress'] = d['_percent_str']

    asyncio.create_task(download_task())
    
    return {'download_id': download_id}

@app.get("/api/progress/{download_id}")
async def get_download_progress(download_id: str):
    status = download_status.get(download_id)
    if not status:
        raise HTTPException(status_code=404, detail="Download ID not found")
    
    return status

def remove_file(path: str):
    try:
        os.remove(path)
    except Exception:
        pass

@app.get("/api/download-file/{download_id}")
async def get_download_file(download_id: str, background_tasks: BackgroundTasks):
    temp_filename = f"temp_{download_id}.mp4"
    if not os.path.exists(temp_filename):
        raise HTTPException(status_code=404, detail="File not found")
    
    # Schedule file deletion after response is sent
    background_tasks.add_task(remove_file, temp_filename)
    
    return FileResponse(
        temp_filename,
        headers={'Content-Disposition': f'attachment; filename="download_{download_id}.mp4"'}
    )


@app.post("/api/instagram-login")
async def instagram_login(request: InstagramLoginRequest):
    """Authenticate with Instagram and save cookies for yt-dlp"""
    try:
        cookies_file = 'instagram_cookies.txt'
        
        ydl_opts = {
            'quiet': False,
            'no_warnings': False,
            'cookiefile': cookies_file,
            'username': request.username,
            'password': request.password,
            'http_headers': {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            },
        }
        
        # Test login by trying to fetch a known Instagram URL
        test_url = "https://www.instagram.com/reel/test/"
        
        with YoutubeDL(ydl_opts) as ydl:
            try:
                # This will attempt login
                ydl.extract_info(test_url, download=False)
            except Exception as e:
                # Expected to fail on test URL, but cookies should be saved
                pass
        
        if os.path.exists(cookies_file):
            return JSONResponse({
                'status': 'success',
                'message': 'Instagram login successful. Cookies saved.',
                'authenticated': True
            })
        else:
            return JSONResponse({
                'status': 'error',
                'message': 'Login failed. Cookies not saved.',
                'authenticated': False
            }, status_code=400)
            
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=400, detail=f"Login error: {str(e)}")


@app.get("/api/instagram-status")
async def instagram_status():
    """Check if Instagram is authenticated"""
    cookies_file = 'instagram_cookies.txt'
    authenticated = os.path.exists(cookies_file)
    
    return JSONResponse({
        'authenticated': authenticated,
        'message': 'Instagram is authenticated' if authenticated else 'Instagram not authenticated. Login required for private content.'
    })


@app.post("/api/instagram-logout")
async def instagram_logout():
    """Clear Instagram authentication"""
    try:
        cookies_file = 'instagram_cookies.txt'
        if os.path.exists(cookies_file):
            os.remove(cookies_file)
        
        return JSONResponse({
            'status': 'success',
            'message': 'Logged out from Instagram'
        })
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Logout error: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)