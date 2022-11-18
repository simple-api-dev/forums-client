<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Edit Moderator</title>
    <link rel="stylesheet" href="resources/css/app.css">
</head>
<body>
<div class="container mt-3 mb-3">

    <h3>Edit Moderator</h3>
    <form action="http://127.0.0.1:8000/updateModerator" method="POST" enctype="multipart/form-data">
        @csrf
        <input type="hidden" name="id" id="id" value="{{$moderator_content->id}}">

        <div>{{$moderator_content->author_id}}</div>
        <div class="form-group">
            <label for="status">Status</label>
            <select class="form-control" required name="status" id="status">
                @foreach($statuses  as $key => $value)
                    <option
                        value="{{ $key }}" {{$moderator_content->status == $key  ? 'selected' : ''}}>{{ $value}}</option>
                @endforeach
            </select>
        </div>

        <input type="reset" name="reset" value="Reset" class="btn btn-dark">
        <input type="submit" name="submit" value="Submit" class="btn btn-dark">
    </form>
</div>
</body>

</html>
