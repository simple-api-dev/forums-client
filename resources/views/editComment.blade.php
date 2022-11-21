<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Forum-Client</title>
    <link rel="stylesheet" href="resources/css/app.css">
</head>

<body>
<h3>Edit Topic</h3>
<form action="{{getenv('FORUM_CLIENT')}}/updateComment" method="POST">
    @csrf
    <input type="hidden" name="id" id="id" value="{{$topic_content->id}}">

    <div>
        <label for="body">Body</label>
        <input type="text" name="body" id="body" value="{{$topic_content->body}}">
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

    <input type="reset" name="reset" value="Reset">
    <input type="submit" name="submit" value="Submit">
</form>
</body>

</html>
