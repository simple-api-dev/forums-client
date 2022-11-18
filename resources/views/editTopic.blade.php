<!DOCTYPE html>
<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Forum-Client</title>
    <link rel="stylesheet" href="resources/css/app.css">
</head>

<body>
<h3>Edit Topic</h3>
<form action="{{getenv('FORUM_CLIENT')}}/updateTopic" method="POST">
    @csrf
    <input type="hidden" name="slug" id="slug" value="{{$topic_content->slug}}">

    <div>
        <label for="title">Title</label>
        <input type="text" name="title" id="title" value="{{$topic_content->title}}">
    </div>

    <div>
        <label for="body">Body</label>
        <input type="text" name="body" id="body" value="{{$topic_content->body}}">
    </div>

    <div>
        <label for="type">Type</label>
        <select required name="type" id="type">
            @foreach($types  as $key => $value)
                <option
                    value="{{ $key }}" {{$topic_content->type == $key  ? 'selected' : ''}}>{{ $value}}</option>
            @endforeach
        </select>
    </div>

    <div>
        <label for="status">Status</label>
        <select required name="status" id="status">
            @foreach($statuses  as $key => $value)
                <option
                    value="{{ $key }}" {{$topic_content->status == $key  ? 'selected' : ''}}>{{ $value}}</option>
            @endforeach
        </select>
    </div>

    <div>
        <label for="author_id">Author_id</label>
        <input type="text" name="author_id" id="author_id" value="{{$topic_content->author_id}}">
    </div>

    <input type="reset" name="reset" value="Reset">
    <input type="submit" name="submit" value="Submit">
</form>
</body>
</html>
