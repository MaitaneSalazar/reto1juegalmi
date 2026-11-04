import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, catchError, map, switchMap, tap, throwError } from 'rxjs';
import { environment } from '../../environments/environment';
import { FUENTE_DATOS } from '../factories/fuente-datos.factory';
import { Usuario } from '../models/usuario.model';

// Lo que se guarda tras iniciar sesión
export interface Sesion {
  token: string;      // JWT que devuelve la API (en modo ejemplo, uno inventado)
  usuario: Usuario;
}

// Datos del formulario de registro
export interface NuevoUsuario {
  nombre: string;
  apellido1: string;
  apellido2?: string;
  dni: string;
  telefono: string;
  email: string;
  password: string;
}

const CLAVE = 'juegalmi_sesion';       // clave en localStorage
const CLAVE_DEMO = '1234';             // contraseña de los usuarios de ejemplo

@Injectable({ providedIn: 'root' })
export class SesionService {
  private http = inject(HttpClient);
  private fuente = inject(FUENTE_DATOS);

  private sesion = signal<Sesion | null>(this.leer());

  readonly usuario = computed(() => this.sesion()?.usuario ?? null);
  readonly token = computed(() => this.sesion()?.token ?? null);
  readonly logueado = computed(() => this.sesion() !== null);
  readonly esTecnico = computed(() => this.usuario()?.rol === 'TECNICO');

  // "Ane Etxeberria"
  readonly nombreCompleto = computed(() => {
    const u = this.usuario();
    return u ? `${u.nombre} ${u.apellido1}` : '';
  });

  // "AE"
  readonly iniciales = computed(() => {
    const u = this.usuario();
    return u ? (u.nombre[0] + u.apellido1[0]).toUpperCase() : '';
  });

  // ---------------------------------------------------------- LOGIN
  login(email: string, password: string): Observable<Usuario> {
    const peticion$ = environment.usarDatosEjemplo
      ? this.loginEjemplo(email, password)
      : this.http.post<Sesion>(`${environment.apiUrl}/login`, { email, password });

    return peticion$.pipe(
      tap(s => this.guardar(s)),
      map(s => s.usuario),
      catchError(e => throwError(() => new Error(this.mensaje(e)))),
    );
  }

  private loginEjemplo(email: string, password: string): Observable<Sesion> {
    return this.fuente.listar<Usuario & { password?: string }>('usuarios', { email }).pipe(
      map(lista => {
        const u = lista[0];
        if (!u || password !== (u.password ?? CLAVE_DEMO)) throw new Error('Email o contraseña incorrectos.');
        const { password: _, ...usuario } = u;
        return { token: `demo-${u.id}`, usuario };
      }),
    );
  }

  // ---------------------------------------------------------- REGISTRO
  registrar(datos: NuevoUsuario): Observable<Usuario> {
    const peticion$ = environment.usarDatosEjemplo
      ? this.registroEjemplo(datos)
      : this.http.post<Sesion>(`${environment.apiUrl}/registro`, datos);

    return peticion$.pipe(
      tap(s => this.guardar(s)),
      map(s => s.usuario),
      catchError(e => throwError(() => new Error(this.mensaje(e)))),
    );
  }

  private registroEjemplo(datos: NuevoUsuario): Observable<Sesion> {
    return this.fuente.listar<Usuario>('usuarios', { email: datos.email }).pipe(
      switchMap(lista => {
        if (lista.length) return throwError(() => new Error('Ya existe una cuenta con ese email.'));
        return this.fuente.crear<Usuario & { password: string }>('usuarios', { ...datos, rol: 'CLIENTE' });
      }),
      map(nuevo => {
        const { password: _, ...usuario } = nuevo;
        return { token: `demo-${nuevo.id}`, usuario };
      }),
    );
  }

  // ---------------------------------------------------------- ACTUALIZAR DATOS (Datos personales y Direcciones)
  actualizarDatos(cambios: Partial<Usuario>): Observable<Usuario> {
    const s = this.sesion();
    if (!s) return throwError(() => new Error('No hay sesión.'));
    return this.fuente.actualizar<Usuario>('usuarios', s.usuario.id, cambios).pipe(
      map(u => ({ ...s.usuario, ...u, ...cambios })),
      tap(usuario => this.guardar({ ...s, usuario })),      // la sesión guardada también se actualiza
      catchError(e => throwError(() => new Error(this.mensaje(e)))),
    );
  }

  // ---------------------------------------------------------- CERRAR SESIÓN
  cerrar(): void {
    this.sesion.set(null);
    try { localStorage.removeItem(CLAVE); } catch { /* sin almacenamiento */ }
  }

  // ---------------------------------------------------------- AUXILIARES
  private guardar(s: Sesion): void {
    this.sesion.set(s);
    try { localStorage.setItem(CLAVE, JSON.stringify(s)); } catch { /* sin almacenamiento */ }
  }

  private leer(): Sesion | null {
    try { return JSON.parse(localStorage.getItem(CLAVE) ?? 'null'); } catch { return null; }
  }

  // Traduce el error a un mensaje claro (formato del backend: { mensaje, campos })
  private mensaje(e: unknown): string {
    if (e instanceof HttpErrorResponse) {
      if (e.status === 0) return 'No se puede conectar con el servidor.';
      if (e.status === 401) return 'Email o contraseña incorrectos.';
      if (e.status === 409) return 'Ya existe una cuenta con ese email.';
      const campos = e.error?.campos as Record<string, string> | undefined;
      if (campos && Object.keys(campos).length) return Object.values(campos)[0];
      return e.error?.mensaje ?? e.error?.message ?? 'Ha ocurrido un error. Inténtalo de nuevo.';
    }
    return e instanceof Error ? e.message : 'Ha ocurrido un error.';
  }
}
