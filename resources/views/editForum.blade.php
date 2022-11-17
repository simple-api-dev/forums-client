<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Edit Forum</title>
    <link rel="stylesheet" href="resources/css/app.css">
</head>
<body>
<div class="container mt-3 mb-3">

    <h3>Edit Forum</h3>
    <form action="http://127.0.0.1:8000/updateForum" method="POST" enctype="multipart/form-data">
        @csrf
        <input type="hidden" name="id" id="id" value="{{$forum_content->id}}">

        <div class="form-group">
            <label for="body">Body</label>
            <input type="text" class="form-control" name="body" id="body" value="{{$forum_content->body}}">
        </div>

        <div class="form-group">
            <label for="status">Status</label>
            <select class="form-control" required name="status" id="status">
                @foreach($statuses  as $key => $value)
                    <option
                        value="{{ $key }}" {{$forum_content->status == $key  ? 'selected' : ''}}>{{ $value}}</option>
                @endforeach
            </select>
        </div>

        <input type="reset" name="reset" value="Reset" class="btn btn-dark">
        <input type="submit" name="submit" value="Submit" class="btn btn-dark">
    </form>
</div>
</body>

</html>
