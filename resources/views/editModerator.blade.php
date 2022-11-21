<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Forum-Client</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    @vite('resources/css/app.css')
</head>

<body>
<h3>Edit Moderator</h3>
<form action="{{getenv('FORUM_CLIENT')}}/updateModerator" method="POST">
    @csrf
    <input type="hidden" name="forum_id" id="forum_id" value="{{$forum_id}}">
    <input type="hidden" name="forum_slug" id="forum_slug" value="{{$forum_slug}}">
    <input type="hidden" name="id" id="id" value="{{$moderator_content->id}}">

    <div class="p-2">
        <label class="font-extrabold">Author Id</label>
        <div>
            <span class="bg-slate-100">{{$moderator_content->author_id}}</span>
        </div>
    </div>

    <div class="p-2">
        <label class="font-extrabold" for="status">Status</label>
        <div>
        <select required name="status" id="status">
            @foreach($statuses  as $key => $value)
                <option
                    value="{{ $key }}" {{$moderator_content->status == $key  ? 'selected' : ''}}>{{ $value}}</option>
            @endforeach
        </select>
        </div>
    </div>

    <input type="reset" name="reset" value="Reset">
    <input type="submit" name="submit" value="Submit">
</form>
</body>
</html>
