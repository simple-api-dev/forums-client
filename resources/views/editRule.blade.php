<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Forum-Client</title>
</head>

<body>
<h3>Edit Rule</h3>
<form action="{{getenv('FORUM_CLIENT')}}/updateRule" method="POST">
    @csrf
    <input type="hidden" name="id" id="id" value="{{$rule_content->id}}">

    <div>
        <label for="body">Body</label>
        <input type="text" name="body" id="body" value="{{$rule_content->body}}">
    </div>

    <div>
        <label for="status">Status</label>
        <select required name="status" id="status">
            @foreach($statuses  as $key => $value)
                <option
                    value="{{ $key }}" {{$rule_content->status == $key  ? 'selected' : ''}}>{{ $value}}</option>
            @endforeach
        </select>
    </div>

    <div>
        <label for="author_id">author_id</label>
        <input type="text" name="author_id" id="author_id" value="{{$rule_content->author_id}}">
    </div>

    <input type="reset" name="reset" value="Reset">
    <input type="submit" name="submit" value="Submit">
</form>
</body>
</html>
