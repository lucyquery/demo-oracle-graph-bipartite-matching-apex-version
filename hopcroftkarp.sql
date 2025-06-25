-- You should run this script in a database that has Java Stored procedure enabled
-- and also supports a client that supports 'set define off' (sqlplus or sqlcl).

set define off

drop function if exists matching;
drop type if exists int_array_table;
drop type if exists int_array_row;
drop java source if exists "HopcroftKarp";

create and compile java source named "HopcroftKarp" as
import java.util.*;
import java.sql.*;
import oracle.sql.*;
import oracle.jdbc.*;

public class HopcroftKarp {
    static final int NIL = 0;
    static final int INF = Integer.MAX_VALUE;

    private Map<Integer, Integer> uIndexMap = new HashMap<>();
    private Map<Integer, Integer> vIndexMap = new HashMap<>();
    private Map<Integer, Integer> revUMap = new HashMap<>();
    private Map<Integer, Integer> revVMap = new HashMap<>();

    private int U, V;
    private List<Integer>[] adj;
    private int[] pairU, pairV, dist;

    public HopcroftKarp(List<Integer> leftNodes,
                             List<Integer> rightNodes,
                             List<int[]> edges) {

        // Map external IDs to internal indices
        int uCounter = 1;
        for (int u : leftNodes) {
            uIndexMap.put(u, uCounter);
            revUMap.put(uCounter, u);
            uCounter++;
        } 

        int vCounter = 1;
        for (int v : rightNodes) {
            vIndexMap.put(v, vCounter);
            revVMap.put(vCounter, v);
            vCounter++;
        }

        this.U = leftNodes.size();
        this.V = rightNodes.size();

        adj = new ArrayList[U + 1];
        for (int i = 0; i <= U; i++) {
            adj[i] = new ArrayList<>();
        }

        for (int[] edge : edges) {
            int u = uIndexMap.get(edge[0]);
            int v = vIndexMap.get(edge[1]);
            adj[u].add(v);
        }

        pairU = new int[U + 1];
        pairV = new int[V + 1];
        dist = new int[U + 1];
    }

    private boolean bfs() {
        Queue<Integer> queue = new LinkedList<>();

        for (int u = 1; u <= U; u++) {
            if (pairU[u] == NIL) {
                dist[u] = 0;
                queue.add(u);
            } else {
                dist[u] = INF;
            }
        }
        dist[NIL] = INF;

        while (!queue.isEmpty()) {
            int u = queue.poll();
            if (dist[u] < dist[NIL]) {
                for (int v : adj[u]) {
                    if (pairV[v] == NIL) {
                        dist[NIL] = dist[u] + 1;
                    } else if (dist[pairV[v]] == INF) {
                        dist[pairV[v]] = dist[u] + 1;
                        queue.add(pairV[v]);
                    }
                }
            }
        }

        return dist[NIL] != INF;
    }

    private boolean dfs(int u) {
        if (u != NIL) {
            for (int v : adj[u]) {
                if (dist[pairV[v]] == dist[u] + 1 && dfs(pairV[v])) {
                    pairV[v] = u;
                    pairU[u] = v;
                    return true;
                }
            }
            dist[u] = INF;
            return false;
        }
        return true;
    }

    public int maxMatching() {
        int matching = 0;
        while (bfs()) {
            for (int u = 1; u <= U; u++) {
                if (pairU[u] == NIL && dfs(u)) {
                    matching++;
                }
            }
        }
        return matching;
    }

    public List<int[]> getMatchedPairs() {
        List<int[]> result = new ArrayList<>();
        for (int u = 1; u <= U; u++) {
            int v = pairU[u];
            if (v != NIL) {
                result.add(new int[]{revUMap.get(u), revVMap.get(v)});
            }
        }
        return result;
    }
    
    public static oracle.sql.ARRAY runMatching(ResultSet rs) throws SQLException {
        Connection conn = DriverManager.getConnection("jdbc:default:connection:");

        List<Integer> leftNodes  = new ArrayList<>();
        List<Integer> rightNodes = new ArrayList<>();
        List<int[]> edges        = new ArrayList<>();

        while (rs.next()) {
            leftNodes.add(rs.getInt(1));
            rightNodes.add(rs.getInt(2));
            edges.add(new int[]{rs.getInt(1),rs.getInt(2)});            
        }

        HopcroftKarp hk = new HopcroftKarp(leftNodes, rightNodes, edges);  
        int matching = hk.maxMatching();      

        StructDescriptor structDesc = StructDescriptor.createDescriptor("INT_ARRAY_ROW", conn);
        ArrayDescriptor  arrayDesc  = ArrayDescriptor.createDescriptor("INT_ARRAY_TABLE", conn);

        STRUCT[] struct = new STRUCT[matching];
        int idx = 0;

        for (int[] pair : hk.getMatchedPairs()) {
            Object[] attrs = new Object[]{pair[0], pair[1]};
            STRUCT s = new STRUCT(structDesc, conn, attrs);
            struct[idx] = s;
            idx++;
        }
        
        return new ARRAY( arrayDesc, conn, struct );
    }
}
/

create type int_array_row as object (
    operator_id  NUMBER,
    task_id   NUMBER
);
/


create type int_array_table as table of int_array_row;
/


create function matching(p_cursor SYS_REFCURSOR) return int_array_table as
language java
name 'HopcroftKarp.runMatching(java.sql.ResultSet) return oracle.sql.ARRAY';
/

-- test using sql
select operator_id, task_id
from (values
        (10, 1), (10, 2), (10, 3),
        (20, 2),
        (30, 3)            
) a (operator_id, task_id);

-- hopcroft karp
select * from table(matching(cursor(
    select operator_id, task_id
    from   (values
            (10, 1), (10, 2), (10, 3),
            (20, 2),
            (30, 3)            
        ) a (operator_id, task_id)
)));

-- bipartite graph
drop property graph if exists g;
drop table if exists is_assigned;
drop table if exists task;
drop table if exists operator;

create table task     (id int generated always as identity primary key, name varchar(20));
create table operator (id int generated always as identity primary key, name varchar(20));

create table is_assigned (id int generated always as identity primary key,
                          from_id int references task(id),
                          to_id int references operator(id));

create property graph g
vertex tables (
    task key (id), operator key (id)
)
edge tables (
    is_assigned key (id)
        source key (from_id)    references task (id)
        destination key (to_id) references operator (id)
);

insert into task (name)                  values ('task1'), ('task2'), ('task3');
insert into operator (name)              values ('operator1'), ('operator2'), ('operator3');
insert into is_assigned (from_id, to_id) values (1, 1), (1, 2), (1, 3), (2, 2), (3, 3);
commit;

-- bipartite graph query
select task, operator
from graph_table(g
    match (t is task)-[e is is_assigned]->(o is operator)
    columns (t.id as task, o.id as operator)
);

-- bipartite graph query using Hopcroft karp
select * from table(matching(cursor(
    select task, operator
    from graph_table(g
        match (t is task)-[e is is_assigned]->(o is operator)
        columns (t.id as task, o.id as operator)
    )
)));

